require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

if ENV.key? 'CI'
	task default: [:spec, :rubocop, :coveralls]
else
	task default: [:spec, :rubocop]
end
spec_pattern = 'spec/**/*_spec.rb'
def_spec_options = '--color --format documentation'

desc 'Run unit tests only'
RSpec::Core::RakeTask.new(:spec) do |spec|
	spec.pattern = spec_pattern
	spec.rspec_opts = def_spec_options
end

RuboCop::RakeTask.new(:rubocop) do |t|
	t.options = ['--display-cop-names']
end

if ENV.key? 'CI'
	require 'coveralls/rake/task'
	Coveralls::RakeTask.new
end
