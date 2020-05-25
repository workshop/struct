require_relative '../spec_helper'

RSpec.describe StructCore::Specfile do
	describe '#initialize' do
		it 'creates a Specfile with the expected values' do
			version = StructCore::SPEC_VERSION_300
			base_dir = Dir.tmpdir
			target = StructCore::Specfile::Target.new '', '', '', [], [], [], '', []
			config = StructCore::Specfile::Configuration.new '', [], {}, 'debug'

			spec = StructCore::Specfile.new version, [target], [config], [], base_dir

			expect(spec.version).to eq(version)
			expect(spec.base_dir).to eq(base_dir)
			expect(spec.targets).to include(target)
			expect(spec.configurations).to include(config)
		end
	end

	describe '#parse' do
		it 'creates a parser object when parsing if one has not been provided' do
			fake_parser_result = {}
			parse_arg = '1/2/3.yaml'

			allow_any_instance_of(StructCore::Specparser).to receive(:parse).and_return(fake_parser_result)
			expect(StructCore::Specfile.parse(parse_arg, nil)).to equal(fake_parser_result)
		end

		it 'uses an existing parser object when parsing if one has been provided' do
			fake_parser_result = {}
			parse_arg = '1/2/3.yaml'
			parser = double('parser', parse: fake_parser_result, register: nil, register_defaults: nil)

			expect(StructCore::Specfile.parse(parse_arg, parser)).to equal(fake_parser_result)
		end
	end

	describe '#write' do
		it 'creates a writer object when writing if one has not been provided' do
			fake_writer_result = {}
			write_arg = '1/2/3.yaml'

			version = StructCore::SPEC_VERSION_300
			base_dir = Dir.tmpdir
			target = StructCore::Specfile::Target.new '', '', '', [], [], [], '', []
			config = StructCore::Specfile::Configuration.new '', [], {}, 'debug'

			spec = StructCore::Specfile.new version, [target], [config], [], base_dir

			allow_any_instance_of(StructCore::Specwriter).to receive(:write_spec).and_return(fake_writer_result)
			expect(spec.write(write_arg, nil)).to equal(fake_writer_result)
		end

		it 'uses an existing writer object when writing if one has been provided' do
			fake_writer_result = {}
			write_arg = '1/2/3.yaml'

			version = StructCore::SPEC_VERSION_300
			base_dir = Dir.tmpdir
			target = StructCore::Specfile::Target.new '', '', '', [], [], [], '', []
			config = StructCore::Specfile::Configuration.new '', [], {}, 'debug'

			spec = StructCore::Specfile.new version, [target], [config], [], base_dir
			writer = double('writer', write_spec: fake_writer_result, register: nil, register_defaults: nil, write_configuration: nil, write_target: nil)

			expect(spec.write(write_arg, writer)).to equal(fake_writer_result)
		end
	end
end