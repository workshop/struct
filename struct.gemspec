# coding: utf-8
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |spec|
  spec.authors       = ['Rhys Cox']
  spec.email         = ['contact@struct.io']
  spec.summary       = 'Xcode projects - simplified'
  spec.description   = "Struct provides structure and predictability for Xcode projects.\n" +
                       'Define your project with a simple project spec, and Struct does the rest.'
  spec.homepage      = 'https://www.github.com/lyptt/struct'

  spec.files         = Dir['{lib,res}/**/*'].reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ['struct']
  spec.name          = 'struct'
  spec.require_paths = ['lib']
  spec.version       = StructCore::VERSION
  spec.licenses      = ['MIT']
  spec.required_ruby_version = '>= 2.2.5'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.47.1'
  spec.add_development_dependency 'coveralls', '~> 0.8.19'
  spec.add_development_dependency 'fastlane', '~> 2.19', '>= 2.19.3'
  spec.add_dependency 'slop', '~> 4.0'
  spec.add_dependency 'paint', '~> 1.0.1'
  spec.add_dependency 'xcodeproj', '~> 1.4.2'
  spec.add_dependency 'listen', '~> 3.1.5'
  spec.add_dependency 'semantic', '~> 1.4.1'
  spec.add_dependency 'awesome_print', '~> 1.7.0'
  spec.add_dependency 'mustache', '~> 1.0.0'
  spec.add_dependency 'inquirer', '~> 0.2.1'
  spec.add_dependency 'excon', '~> 0.54.0'
  spec.add_dependency 'ruby_deep_clone', '~> 0.7.2'
end
