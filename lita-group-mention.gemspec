Gem::Specification.new do |spec|
  spec.name          = 'lita-group-mention'
  spec.version       = '0.0.1'
  spec.authors       = ['Ben House']
  spec.email         = ['ben@benhouse.io']
  spec.description   = %w(TODO: Add a description)
  spec.summary       = %w(TODO: Add a summary)
  spec.homepage      = 'TODO: Add a homepage'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.2'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'rubocop'
end
