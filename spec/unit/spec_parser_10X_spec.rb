require 'yaml'
require_relative '../spec_helper'

RSpec.describe StructCore::Specparser10X do
	describe '#can_parse_version' do
		it 'specifies that it can only parse Spec versions 1.0.X' do
			parser = StructCore::Specparser10X.new

			expect(parser.can_parse_version(Semantic::Version.new('1.0.0'))).to be_truthy
			expect(parser.can_parse_version(Semantic::Version.new('1.0.1'))).to be_truthy
			expect(parser.can_parse_version(Semantic::Version.new('1.0.1001'))).to be_truthy
			expect(parser.can_parse_version(Semantic::Version.new('1.1.0'))).to be_falsey
		end
	end

	describe '#parse' do
		it 'can parse a specfile with only configurations' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_2.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to eq(2)
		end

		it 'raises an error if a project doesn\'t contain configurations' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_3.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file }.to raise_error(StandardError)
		end

		it 'can parse a specfile with only 1 configuration' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_4.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to eq(1)
		end

		it 'raises an error if a project has an invalid targets section' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_5.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file }.to raise_error(StandardError)
		end

		it 'raises an error if a project has an invalid configurations section' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_6.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file }.to raise_error(StandardError)
		end

		it 'raises an error if a project has an invalid profiles section in a configuration block' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_7.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file }.to raise_error(StandardError)
		end

		it 'raises an error if a project has a missing profiles section in a configuration block' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_8.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file }.to raise_error(StandardError)
		end

		it 'can parse a specfile with invalid overrides or types' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_9.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to eq(1)
		end

		it 'can parse a specfile with overrides and types' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_10.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to eq(1)
			expect(proj.configurations[0].name).to eq('my-configuration')
			expect(proj.configurations[0].type).to eq('debug')
		end

		it 'skips targets within a specfile that contain no configuration' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_11.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file
			expect(proj).to be_an StructCore::Specfile
			expect(proj.targets.count).to eq(0)
		end

		it 'can parse a specfile with a string sources entry' do
			project_file = File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_12.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, project_file
			expect(proj).to be_an StructCore::Specfile
			expect(proj.targets[0].source_dir.count).to eq(1)
			expect(proj.targets[0].source_dir[0]).to be_truthy
		end
	end
end