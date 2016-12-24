require_relative '../spec_helper'

RSpec.describe Xcodegen::Specfile do
	describe '#initialize' do
		it 'creates a Specfile with the expected values' do
			version = Semantic::Version.new('1.0.0')
			base_dir = Dir.tmpdir
			target = Xcodegen::Specfile::Target.new '', '', '', [], [], [], '', []
			config = Xcodegen::Specfile::Configuration.new '', [], {}, 'debug'

			spec = Xcodegen::Specfile.new version, [target], [config], base_dir

			expect(spec.version).to eq(version)
			expect(spec.base_dir).to eq(base_dir)
			expect(spec.targets).to include(target)
			expect(spec.configurations).to include(config)
		end
	end
end