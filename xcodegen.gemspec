# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xcodegen/version'

Gem::Specification.new do |spec|
  spec.name          = 'xcodegen'
  spec.version       = Xcodegen::VERSION
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
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = Dir['LICENSE.md', 'README.md', 'lib/**/*', 'bin/**/*'].reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
end
