require_relative '../spec_helper'

RSpec.describe StructCore::Specwriter13X do
	describe '#write' do
		it 'can write a fully featured spec file' do
			project_file = File.join(File.dirname(__FILE__), 'support_files/spec_writer_13X_full_spec/project.yml')
			test_hash = YAML.load_file project_file
			parser = StructCore::Specparser13X.new

			spec = parser.parse StructCore::SPEC_VERSION_130, test_hash, project_file

			spec_2_data = nil

			expect { spec_2_data = StructCore::Specwriter13X.new.write_spec spec, project_file, true }.to_not raise_error
			expect(spec_2_data).to_not be_nil
			spec_2_hash = YAML.load spec_2_data

			spec_2 = nil
			expect { spec_2 = parser.parse StructCore::SPEC_VERSION_130, spec_2_hash, project_file }.to_not raise_error
			expect(spec_2).to_not be_nil

			expect(spec_2.configurations.length).to eq(2)
			expect(spec_2.targets.length).to eq(1)
			expect(spec_2.variants.length).to eq(3)
			expect(spec_2.targets[0].references.length).to eq(2)
			expect(spec_2.variants[2].targets[0].references.length).to eq(2)
		end
	end
end