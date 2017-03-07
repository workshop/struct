require_relative '../spec_helper'

RSpec.describe StructCore::Migrator do
	describe '#migrate' do
		it 'can migrate projects with xcconfig files instead of configuration settings' do
			xcodeproj_file = File.join(File.dirname(__FILE__), 'support_files', 'xcconfig', 'Xcconfig.xcodeproj')
			spec = nil

			expect { spec = StructCore::Migrator.migrate xcodeproj_file, Dir.tmpdir, true }.not_to raise_error
			expect(spec).to_not be_nil
		end
	end
end