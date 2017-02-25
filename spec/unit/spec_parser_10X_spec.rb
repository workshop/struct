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
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_2.yml')
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_2.yml'
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to equal(2)
		end

		it 'raises an error if a project doesn\'t contain configurations' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_3.yml')
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_3.yml' }.to raise_error(StandardError)
		end

		it 'can parse a specfile with only 1 configuration' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_4.yml')
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_4.yml'
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to equal(1)
		end

		it 'raises an error if a project has an invalid targets section' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_5.yml')
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_5.yml' }.to raise_error(StandardError)
		end

		it 'raises an error if a project has an invalid configurations section' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_6.yml')
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_6.yml' }.to raise_error(StandardError)
		end

		it 'raises an error if a project has an invalid profiles section in a configuration block' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_7.yml')
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_7.yml' }.to raise_error(StandardError)
		end

		it 'raises an error if a project has a missing profiles section in a configuration block' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_8.yml')
			parser = StructCore::Specparser10X.new

			expect { parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_8.yml' }.to raise_error(StandardError)
		end

		it 'can parse a specfile with invalid overrides or types' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_9.yml')
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_9.yml'
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to equal(1)
		end

		it 'can parse a specfile with overrides and types' do
			test_hash = YAML.load_file File.join(File.dirname(__FILE__), '../support/spec_parser_10X_test_10.yml')
			parser = StructCore::Specparser10X.new

			proj = parser.parse Semantic::Version.new('1.0.0'), test_hash, 'spec_parser_10X_test_10.yml'
			expect(proj).to be_an StructCore::Specfile
			expect(proj.configurations.count).to equal(1)
			expect(proj.configurations[0].name).to eq('my-configuration')
			expect(proj.configurations[0].type).to eq('debug')
		end
	end
end