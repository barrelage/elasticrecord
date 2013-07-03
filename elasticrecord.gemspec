$LOAD_PATH.unshift File.expand_path '../lib', __FILE__
require 'elasticrecord/version'

Gem::Specification.new do |s|
  s.name        = 'elasticrecord'
  s.version     = ElasticRecord::VERSION
  s.summary     = 'Simple ORM for Elasticsearch'
  s.description = 'Simple ORM for Elasticsearch'

  s.files       = Dir['lib/**/*']

  s.has_rdoc    = false

  s.authors     = [ 'Evan Owen' ]
  s.email       = %w[ kainosnoema@gmail.com ]
  s.homepage    = 'https://github.com/kainosnoema/elasticrecord'

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'activemodel',   '>= 3.2'
  s.add_dependency 'activesupport'
  s.add_dependency 'connection_pool'
  s.add_dependency 'stretcher',     '~> 1.16.0'

  s.add_development_dependency 'cane',       '~> 2.3.x'
  s.add_development_dependency 'rake',       '~> 10.0.x'
  s.add_development_dependency 'rspec',      '~> 2.13.x'
end
