# coding: utf-8
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |spec|
  spec.authors       = ['Rhys Cox']
  spec.email         = ['account+github@lyptt.uk']
  spec.summary       = 'A tool to make managing an Xcode project way easier'
  spec.description   = 'Xcodegen comes in two parts - a file watcher that auto-generates '\
                       'a project based on a simple project specification written in YAML or '
                       'JSON, and options to assist in adding new files and targets to your '\
                       'dynamic project.'
  spec.homepage      = 'https://www.github.com/lyptt/xcodegen'

  spec.files         = Dir['{lib,res}/**/*'].reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ['xcodegen']
  spec.name          = 'xcodegen'
  spec.require_paths = ['lib']
  spec.version       = Xcodegen::VERSION
  spec.licenses      = ['MIT']
  spec.required_ruby_version = '>= 2.2.5'
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'slop', '~> 4.0'
  spec.add_dependency 'paint', '~> 1.0.1'
  spec.add_dependency 'xcodeproj', '~> 1.4.1'
  spec.add_dependency 'fastlane_core', '~> 0.57.1'
  spec.add_dependency 'listen', '~> 3.1.5'
  spec.add_dependency 'semantic', '~> 1.4.1'
end
