require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: [:spec, :rubocop, :coverage]
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

desc 'Run code coverage'
task :coverage do
	if ENV.key? 'CI'
		require 'coveralls'
		Coveralls.wear!
	else
		puts 'Ignoring code coverage in non-CI environment'
	end
end