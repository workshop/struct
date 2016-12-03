# coding: utf-8
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |spec|
  spec.authors       = ['Rhys Cox']
  spec.email         = ['account+github@lyptt.uk']
  spec.summary       = 'A tool to make managing an Xcode project way easier'
  spec.description   = 'Xcodegen comes in two parts - a file watcher that auto-generates '\
                       'a project based on a simple YAML specification that targets a'\
                       'dynamic source files directory, and options to assist in adding'\
                       'new files and targets to your dynamic project.'
  spec.homepage      = 'https://www.github.com/lyptt/xcodegen'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://localhost:10000'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = Dir['{lib,res}/**/*'].reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ['xcodegen']
  spec.name          = 'xcodegen'
  spec.require_paths = ['lib']
  spec.version       = Xcodegen::VERSION
  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'slop', '~> 4.0'
  spec.add_dependency 'paint', '~> 1.0.1'
  spec.add_dependency 'xcodeproj', '~> 1.4.1'
  spec.add_dependency 'fastlane_core', '~> 0.57.1'
  spec.add_dependency 'filewatcher', '~> 0.4.0'
  spec.add_dependency 'semantic', '~> 1.4.1'
end
