require_relative '../spec_helper'

RSpec.describe StructCore::Specparser12X do
	describe '#can_parse_version' do
		SPEC_VERSION_12X = Semantic::Version.new('1.2.0').freeze

		it 'specifies that it can only parse Spec versions 1.2.X' do
			parser = StructCore::Specparser12X.new

			expect(parser.can_parse_version(SPEC_VERSION_12X)).to be_truthy
			expect(parser.can_parse_version(Semantic::Version.new('1.2.1'))).to be_truthy
			expect(parser.can_parse_version(Semantic::Version.new('1.2.1001'))).to be_truthy
			expect(parser.can_parse_version(Semantic::Version.new('1.3.0'))).to be_falsey
			expect(parser.can_parse_version(Semantic::Version.new('1.1.0'))).to be_falsey
			expect(parser.can_parse_version(Semantic::Version.new('1.0.0'))).to be_falsey
		end

		describe '#parse' do
			it 'can parse a specfile with only configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_2.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(2)
			end

			it 'raises an error if a project doesn\'t contain configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_3.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				expect { parser.parse SPEC_VERSION_12X, test_hash, project_file }.to raise_error(StandardError)
			end

			it 'can parse a specfile with only 1 configuration' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_4.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(1)
			end

			it 'raises an error if a project has an invalid targets section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_5.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				expect { parser.parse SPEC_VERSION_12X, test_hash, project_file }.to raise_error(StandardError)
			end

			it 'raises an error if a project has an invalid configurations section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_6.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				expect { parser.parse SPEC_VERSION_12X, test_hash, project_file }.to raise_error(StandardError)
			end

			it 'raises an error if a project has an invalid profiles section in a configuration block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_7.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				expect { parser.parse SPEC_VERSION_12X, test_hash, project_file }.to raise_error(StandardError)
			end

			it 'raises an error if a project has a missing profiles section in a configuration block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_8.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				expect { parser.parse SPEC_VERSION_12X, test_hash, project_file }.to raise_error(StandardError)
			end

			it 'can parse a specfile with invalid overrides or types' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_9.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(1)
			end

			it 'can parse a specfile with overrides and types' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_10.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(1)
				expect(proj.configurations[0].name).to eq('my-configuration')
				expect(proj.configurations[0].type).to eq('debug')
			end

			it 'skips targets within a specfile that contain no configuration' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_11.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets.count).to eq(0)
			end

			it 'skips targets within a specfile that contain no type' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_12.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets.count).to eq(0)
			end

			it 'can parse a specfile with a string sources entry' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_13.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].source_dir.count).to eq(1)
				expect(proj.targets[0].source_dir[0]).to be_truthy
			end

			it 'can parse a specfile with a i18n-resources entry' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_14.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].res_dir.count).to eq(1)
				expect(proj.targets[0].res_dir[0]).to be_truthy
			end

			it 'can parse a specfile with excludes entries' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_15.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].file_excludes.count).to eq(2)
				expect(proj.targets[0].file_excludes[0]).to eq('a/b/c')
				expect(proj.targets[0].file_excludes[1]).to eq('d/e/f')
			end

			it 'ignores excludes in a specfile with an invalid excludes block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_16.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].file_excludes.count).to eq(0)
			end

			it 'ignores excludes in a specfile with an invalid excludes files block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_17.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].file_excludes.count).to eq(0)
			end

			it 'parses a specfile with an sdkroot framework reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_18.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::SystemFrameworkReference)
			end

			it 'parses a specfile with an sdkroot library reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_19.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::SystemLibraryReference)
			end

			it 'parses a specfile with a local project framework reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_20.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::FrameworkReference)
			end

			it 'ignores a references group in a specfile with an invalid references block' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_21.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(0)
			end

			it 'ignores a reference entry in a specfile if it\'s invalid' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_22.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(0)
			end

			it 'parses a specfile with a local framework reference' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_23.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::LocalFrameworkReference)
			end

			it 'parses a specfile with a local framework reference containing options' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_24.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].references.count).to eq(1)
				expect(proj.targets[0].references[0]).to be_an_instance_of(StructCore::Specfile::Target::LocalFrameworkReference)
				expect(proj.targets[0].references[0].settings['copy']).to eq(false)
				expect(proj.targets[0].references[0].settings['codeSignOnCopy']).to eq(false)
			end

			it 'parses a specfile with a script file' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_25.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].run_scripts.count).to eq(1)
				expect(proj.targets[0].run_scripts[0]).to be_an_instance_of(StructCore::Specfile::Target::RunScript)
			end

			it 'ignores an invalid scripts section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_26.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.targets[0].run_scripts.count).to eq(0)
			end

			it 'parses a specfile with an empty variants section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_27.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
			end

			it 'parses a specfile with an invalid variants section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_28.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
			end

			it 'parses a specfile with a variant not present in the targets section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_29.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants[0].targets.count).to eq(0)
			end

			it 'parses a specfile with an invalid variant in the variants section' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_30.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
			end

			it 'parses a specfile with a valid variant' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_31.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants[0].targets.count).to eq(1)
				expect(proj.variants[0].targets[0].source_dir.count).to eq(1)
				expect(proj.variants[0].targets[0].res_dir.count).to eq(1)
				expect(proj.variants[0].targets[0].configurations[0].settings.key?('SWIFT_ACTIVE_COMPILATION_CONDITIONS')).to eq(true)
				expect(proj.variants[0].targets[0].references.count).to eq(1)
				expect(proj.variants[0].targets[0].file_excludes.count).to eq(1)
				expect(proj.variants[0].targets[0].run_scripts.count).to eq(1)
			end

			it 'parses a specfile with an invalid variant' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_32.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.variants[0].targets.count).to eq(1)
			end

			it 'can parse a specfile with xcconfig-based configurations' do
				project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_12X/spec_parser_12X_test_33.yml')
				test_hash = YAML.load_file project_file
				parser = StructCore::Specparser12X.new

				proj = parser.parse SPEC_VERSION_12X, test_hash, project_file
				expect(proj).to be_an StructCore::Specfile
				expect(proj.configurations.count).to eq(3)
			end
		end
	end
end