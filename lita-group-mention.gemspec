Gem::Specification.new do |spec|
  spec.name          = 'lita-group-mention'
  spec.version       = '1.1.0'
  spec.authors       = ['Ben House']
  spec.email         = ['ben@benhouse.io']
  spec.description   = 'cc a list of users when a group is @mentioned'
  spec.summary       = 'add users to a group, @mention the group, and the plugin will cc each user'
  spec.homepage      = 'https://github.com/bhouse/lita-group-mention'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
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
