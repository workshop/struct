def should_stub_tests_on_incompatible_os
	!ENV['TRAVIS_OS_NAME'].nil? && ENV['TRAVIS_OS_NAME'] != 'osx'
end

# Must remain at the top of the file to properly track coverage
#
# We only run coverage on macOS, as this includes integration tests
# which can only run in macOS that cover XcodeprojWriter.
#
# This prevents coverage being skewed when run on other platforms.
if ENV.key?('CI') && !should_stub_tests_on_incompatible_os
	require 'coveralls'
	Coveralls.wear!
end

require 'semantic'
require 'tmpdir'
require 'yaml'
require_relative '../lib/utils/defines'
require_relative '../lib/spec/spec_file'
require_relative '../lib/refresher/refresher'
require_relative '../lib/spec/parser/spec_parser'
require_relative '../lib/spec/parser/spec_parser_1_1_X'
require_relative '../lib/spec/parser/spec_parser_1_2_X'
require_relative '../lib/spec/parser/spec_parser_1_3_X'
require_relative '../lib/spec/parser/spec_parser_2_0_X'
require_relative '../lib/spec/writer/spec_writer'
require_relative '../lib/spec/writer/spec_writer_1_1_X'
require_relative '../lib/spec/writer/spec_writer_1_2_X'
require_relative '../lib/spec/writer/spec_writer_1_3_X'
require_relative '../lib/spec/writer/spec_writer_2_0_X'
require_relative '../lib/spec/builder/spec_builder'
require_relative '../lib/spec/processor/spec_processor'

def copy_support_files(source_dir, dest_dir)
	Dir.glob("#{source_dir}/**/*").each { |file|
		FileUtils.cp_r file, file.sub(source_dir, dest_dir), {:remove_destination => true}
	}
	Dir.glob("#{source_dir}/**/.**").each { |file|
		FileUtils.cp_r file, file.sub(source_dir, dest_dir), {:remove_destination => true}
	}
end

RSpec.configure do |config|
	config.color = true
	config.tty = true
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
