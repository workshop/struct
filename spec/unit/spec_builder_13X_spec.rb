require_relative '../spec_helper'

RSpec.describe StructCore::SpecBuilder do
	describe '#build' do
		describe 'for Specfile v1.3.0' do
			it 'can build a Specfile with only configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_2.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(2)
			end

			it 'raises an error if a project doesn\'t contain configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_3.rb')

				expect { StructCore::SpecBuilder.build project_file }.to raise_error(StandardError)
			end

			it 'can build a Specfile with only 1 configuration' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_4.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(1)
			end

			it 'raises an error if a project has an invalid targets section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_5.rb')

				expect { StructCore::SpecBuilder.build project_file }.to raise_error(StandardError)
			end

			it 'raises an error if a project has an invalid configurations section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_6.rb')

				expect { StructCore::SpecBuilder.build project_file }.to raise_error(StandardError)
			end

			it 'raises an error if a project has an invalid profiles section in a configuration block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_7.rb')

				expect { StructCore::SpecBuilder.build project_file }.to raise_error(StandardError)
			end

			it 'raises an error if a project has a missing profiles section in a configuration block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_8.rb')

				expect { StructCore::SpecBuilder.build project_file }.to raise_error(StandardError)
			end

			it 'can build a Specfile with invalid overrides or types' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_9.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(1)
			end

			it 'can build a Specfile with overrides and types' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_10.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(1)
				expect(proj.configurations[0].name).to eq('my-configuration')
				expect(proj.configurations[0].type).to eq('debug')
			end

			it 'raises an error if a target within a Specfile contains no configuration' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_11.rb')

				expect { StructCore::SpecBuilder.build project_file }.to raise_error(StandardError)
			end

			it 'raises an error if a target within a Specfile contains no type' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_12.rb')

				expect { StructCore::SpecBuilder.build project_file }.to raise_error(StandardError)
			end

			it 'can build a Specfile with a string sources entry' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_13.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].source_dir.count).to eq(1)
				expect(proj.targets[0].source_dir[0]).to be_truthy
			end

			it 'can build a Specfile with a i18n-resources entry' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_14.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].res_dir.count).to eq(1)
				expect(proj.targets[0].res_dir[0]).to be_truthy
			end

			it 'can build a Specfile with excludes entries' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_15.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].file_excludes.count).to eq(2)
				expect(proj.targets[0].file_excludes[0]).to eq('a/b/c')
				expect(proj.targets[0].file_excludes[1]).to eq('d/e/f')
			end

			it 'ignores excludes in a Specfile with an invalid excludes block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_16.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].file_excludes.count).to eq(0)
			end

			it 'builds a Specfile with an sdkroot framework reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_18.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::SystemFrameworkReference)
			end

			it 'builds a Specfile with an sdkroot library reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_19.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::SystemLibraryReference)
			end

			it 'builds a Specfile with a local project framework reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_20.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::FrameworkReference)
			end

			it 'ignores a references group in a Specfile with an invalid references block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_21.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(0)
			end

			it 'ignores a reference entry in a Specfile if it\'s invalid' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_22.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(0)
			end

			it 'builds a Specfile with a local framework reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_23.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::LocalFrameworkReference)
			end

			it 'builds a Specfile with a local framework reference containing options' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_24.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::LocalFrameworkReference)
				expect(proj.targets[0].references[0].settings['copy']).to eq(false)
				expect(proj.targets[0].references[0].settings['codeSignOnCopy']).to eq(false)
			end

			it 'builds a Specfile with a script file' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_25.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].postbuild_run_scripts.count).to eq(1)
				expect(proj.targets[0].postbuild_run_scripts[0]).to be_an_instance_of(StructCore::Specfile::Target::RunScript)
			end

			it 'ignores an invalid scripts section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_26.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].postbuild_run_scripts.count).to eq(0)
			end

			it 'builds a Specfile with an empty variants section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_27.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
			end

			it 'builds a Specfile with an invalid variants section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_28.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
			end

			it 'builds a Specfile with a variant not present in the targets section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_29.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants[0].targets.count).to eq(0)
			end

			it 'builds a Specfile with an invalid target in a variant block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_30.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
			end

			it 'builds a Specfile with a valid variant' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_31.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants[0].targets.count).to eq(1)
				expect(proj.variants[0].targets[0].source_dir.count).to eq(1)
				expect(proj.variants[0].targets[0].res_dir.count).to eq(1)
				expect(proj.variants[0].targets[0].configurations[0].settings.key?('SWIFT_ACTIVE_COMPILATION_CONDITIONS')).to eq(true)
				expect(proj.variants[0].targets[0].references.count).to eq(1)
				expect(proj.variants[0].targets[0].file_excludes.count).to eq(1)
				expect(proj.variants[0].targets[0].postbuild_run_scripts.count).to eq(1)
			end

			it 'builds a Specfile with an invalid variant' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_32.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants[0].targets.count).to eq(1)
			end

			it 'can build a Specfile with xcconfig-based configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_33.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(3)
			end

			it 'can build a Specfile with xcconfig-based target configuration' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_34.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets.count).to eq(1)
				expect(proj.targets[0].configurations.count).to eq(2)
			end

			it 'can build a Specfile with xcconfig-based target configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_35.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets.count).to eq(1)
				expect(proj.targets[0].configurations.count).to eq(2)
			end
			it 'can build a Specfile with xcconfig-based variant target configuration' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_36.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants.count).to eq(2)
				expect(proj.variants[0].targets.count).to eq(1)
				expect(proj.variants[0].targets[0].configurations.count).to eq(2)
			end

			it 'can build a Specfile with xcconfig-based variant target configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_37.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants.count).to eq(2)
				expect(proj.variants[0].targets.count).to eq(1)
				expect(proj.variants[0].targets[0].configurations.count).to eq(2)
			end

			it 'builds a Specfile with prebuild & postbuild run scripts' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_38.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants[0].targets[0].prebuild_run_scripts.count).to eq(1)
				expect(proj.targets[0].postbuild_run_scripts.count).to eq(1)
			end

			it 'builds a Specfile with an abstract variant' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_39.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants.count).to eq(1)
				expect(proj.variants[0].abstract).to eq(true)
			end

			it 'builds a Specfile with cocoapods' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_40.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.includes_pods).to be_truthy
			end

			it 'builds a Specfile with cocoapods in a variant' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_41.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.includes_pods).to be_truthy
			end

			it 'builds a Specfile that contains library references' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_builder_13X/spec_builder_13X_test_42.rb')

				proj = StructCore::SpecBuilder.build project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::LocalLibraryReference)
				expect(proj.variants[0].targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::LocalLibraryReference)
			end
		end
	end
end