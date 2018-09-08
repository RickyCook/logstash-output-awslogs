# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/plugin_mixins/aws_config"
require "aws-sdk"

Aws.eager_autoload!

# An awslogs output that does nothing.
class LogStash::Outputs::Awslogs < LogStash::Outputs::Base
  include LogStash::PluginMixins::AwsConfig::V2

  config_name "awslogs"
  default :codec, "line"

  config :log_group_name, :validate => :string, :required => true
  config :log_stream_name, :validate => :string, :required => true

  public
  def register
    @client = Aws::CloudWatchLogs::Client.new(aws_options_hash)
    @next_sequence_tokens = {}
  end # def register

  public
  def multi_receive_encoded(events_and_encoded)
    to_send = {}

    events_and_encoded.each do |event, encoded|
      event_log_stream_name = event.sprintf(log_stream_name)
      event_log_group_name = event.sprintf(log_group_name)

      next_sequence_token_key = [event_log_group_name, event_log_stream_name]
      if ! to_send.keys.include? next_sequence_token_key
        to_send.store(next_sequence_token_key, [])
      end
      to_send[next_sequence_token_key].push({
        timestamp: (event.timestamp.time.to_f * 1000).to_int,
        message: encoded,
      })
    end
    to_send.each do |event_log_names, log_events|
      event_log_group_name = event_log_names[0]
      event_log_stream_name = event_log_names[1]
      next_sequence_token_key = [event_log_group_name, event_log_stream_name]

      ident_opts = {
        log_group_name: event_log_group_name,
        log_stream_name: event_log_stream_name,
      }
      send_opts = ident_opts.merge({
        log_events: log_events,
      })

      if @next_sequence_tokens.keys.include? next_sequence_token_key
        send_opts[:sequence_token] = @next_sequence_tokens[next_sequence_token_key]
      else
        resp = @client.describe_log_streams({
          log_group_name: event_log_group_name,
          log_stream_name_prefix: event_log_stream_name,
        })
        if resp.log_streams.length < 1
          @client.create_log_stream(ident_opts)
        else
          resp.log_streams.each do |log_stream_data|
            if log_stream_data.log_stream_name == event_log_stream_name
              send_opts[:sequence_token] = log_stream_data.upload_sequence_token
              break
            end
          end
        end
      end

      resp = @client.put_log_events(send_opts)
      # TODO: handle rejected events with debug message
      @next_sequence_tokens.store(next_sequence_token_key, resp.next_sequence_token)
    end
  end # def multi_receive_encoded
end # class LogStash::Outputs::Awslogs
