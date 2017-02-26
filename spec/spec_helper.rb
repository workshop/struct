require 'semantic'
require 'tmpdir'
require_relative '../lib/struct'

if ENV.key? 'CI'
	require 'coveralls'
	Coveralls.wear!
end

RSpec.configure do |config|
	config.color = true
	config.tty = true
	unless ENV.key? 'CI'
		original_stderr = $stderr
		original_stdout = $stdout
		config.before(:all) do
			# Redirect stderr and stdout
			$stderr = File.open(File::NULL, 'w')
			$stdout = File.open(File::NULL, 'w')
		end
		config.after(:all) do
			$stderr = original_stderr
			$stdout = original_stdout
		end
	end
end
