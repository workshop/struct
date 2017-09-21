require_relative '../spec_helper'
require 'fastlane'

RSpec.describe StructCore::SpecProcessor do
	describe '#process' do
		it 'can write a working project that links to subproject libraries' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_subproj_libraries'), destination

			Dir.chdir(destination) {
				expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error
			}

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}
		end

		it 'can write a working project with shared source files' do
			next if should_stub_tests_on_incompatible_os
			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'shared_source'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}
		end

		it 'can write a working project with generation hooks' do
			next if should_stub_tests_on_incompatible_os
			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'hooks_test'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			expect { StructCore::SpecProcessor.new(File.join(destination, 'Specfile')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}
		end

		it 'can write a working project with file excludes' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_file_excludes'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			project_file = File.join destination, 'beta.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			FileUtils.rm_rf destination
		end

		it 'can write a working project with source flags' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_source_options'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			project_file = File.join destination, 'beta.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			FileUtils.rm_rf destination
		end

		it 'can write a working project with emedded products' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_embedding'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			FileUtils.rm_rf destination
		end

		it 'can write a working project with xcconfig configurations' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_xcconfig'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			project_file = File.join destination, 'beta.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			FileUtils.rm_rf destination
		end

		it 'can write a working project with pre/postbuild run scripts' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_pre_post_run_scripts'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			project_file = File.join destination, 'beta.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			FileUtils.rm_rf destination
		end

		it 'can properly determine source files precendence' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_source_precedence'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			project_file = File.join destination, 'beta.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to raise_error
			}

			FileUtils.rm_rf destination
		end

		it 'strips out invalid characters from variant project filenames' do
			project_file = File.join(File.dirname(__FILE__), 'support_files/xcodeproj_writer_test_variant_filenames/project.yml')
			expect { StructCore::SpecProcessor.new(project_file, true).process }.to_not raise_error
		end

		it 'can write a working project that links to local libraries' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_local_libraries'), destination

			expect { StructCore::SpecProcessor.new(File.join(destination, 'project.yml')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}
		end

		it 'can write a working project with pod references' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_pod_references'), destination

			Dir.chdir(destination) do
				`pod install`
			end

			expect { StructCore::SpecProcessor.new(File.join(destination, 'Specfile')).process }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
			Fastlane.load_actions
			Dir.chdir(File.join(File.dirname(__FILE__), 'support_files')) {
				expect { Fastlane::LaneManager.cruise_lane(nil, 'build', {:project => project_file}, {}) }.to_not raise_error
			}

			FileUtils.rm_rf destination
		end
	end
end
