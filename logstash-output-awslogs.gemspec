Gem::Specification.new do |s|
  s.name          = 'logstash-output-awslogs'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Writes events to AWS CloudWatch logs.'
  s.homepage      = 'https://github.com/rickycook/logstash-output-awslogs'
  s.authors       = ['Ricky Cook']
  s.email         = 'logstash-output-awslogs@auto.thatpanda.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency "logstash-codec-plain"
  s.add_runtime_dependency 'logstash-mixin-aws', '>= 4.3.0'
  s.add_development_dependency "logstash-devutils"
end
