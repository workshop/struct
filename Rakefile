require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task default: :spec
spec_pattern = 'spec/**/*_spec.rb'
def_spec_options = '--color --format documentation'

desc 'Run unit tests only'
RSpec::Core::RakeTask.new(:spec) do |spec|
	spec.pattern = spec_pattern
	spec.rspec_opts = def_spec_options
end