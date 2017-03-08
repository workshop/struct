require_relative '../spec_helper'
require 'fastlane'

RSpec.describe StructCore::XcodeprojWriter do
	describe '#write' do
		it 'can write a working project with xcconfig configurations' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_xcconfig'), destination

			spec = StructCore::Specparser.new.parse File.join(destination, 'project.yml')

			expect { StructCore::XcodeprojWriter.write spec, destination }.to_not raise_error
			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			FileUtils.rm_rf destination
		end
	end
end