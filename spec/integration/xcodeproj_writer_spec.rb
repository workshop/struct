require_relative '../spec_helper'
require 'fastlane'

RSpec.describe StructCore::XcodeprojWriter do
	describe '#write' do
		it 'can write a working project with source flags' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_source_options'), destination

			spec = StructCore::Specparser.new.parse File.join(destination, 'project.yml')

			expect { StructCore::XcodeprojWriter.write spec, destination }.to_not raise_error

			project_file = File.join destination, 'project.xcodeproj'
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

			spec = StructCore::Specparser.new.parse File.join(destination, 'project.yml')

			expect { StructCore::XcodeprojWriter.write spec, destination }.to_not raise_error

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

			spec = StructCore::Specparser.new.parse File.join(destination, 'project.yml')

			expect { StructCore::XcodeprojWriter.write spec, destination }.to_not raise_error

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

			spec = StructCore::Specparser.new.parse File.join(destination, 'project.yml')

			expect { StructCore::XcodeprojWriter.write spec, destination }.to_not raise_error

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

			spec = StructCore::Specparser.new.parse File.join(destination, 'project.yml')

			expect { StructCore::XcodeprojWriter.write spec, destination }.to_not raise_error

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
			destination = Dir.mktmpdir

			project_file = File.join(File.dirname(__FILE__), 'support_files/xcodeproj_writer_test_variant_filenames/project.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser12X.new

			proj = parser.parse StructCore::SPEC_VERSION_121, test_hash, project_file

			expect { StructCore::XcodeprojWriter.write proj, destination }.to_not raise_error
			expect(File.exist?(File.join(destination, 'My_variant_project_file.xcodeproj'))).to be_truthy

			FileUtils.rm_rf destination
		end

		it 'can write a working project that links to local libraries' do
			next if should_stub_tests_on_incompatible_os

			destination = Dir.mktmpdir
			copy_support_files File.join(File.dirname(__FILE__), 'support_files', 'xcodeproj_writer_test_local_libraries'), destination

			spec = StructCore::Specparser.new.parse File.join(destination, 'project.yml')

			expect { StructCore::XcodeprojWriter.write spec, destination }.to_not raise_error

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

			spec = StructCore::SpecBuilder.build File.join(destination, 'Specfile')

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