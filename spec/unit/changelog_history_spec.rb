require_relative '../spec_helper'

def ver(v)
	Semantic::Version.new v
end

RSpec.describe StructCore::RefresherHelpers do
	describe 'build_changelist' do
		it 'should return no changes if on the latest version' do
			versions = %w(0.0.1 1.0.0)
			local_gem_version = ver('1.0.0')
			latest_gem_version = ver('1.0.0')

			expect(StructCore::RefresherHelpers.build_changelist(versions, local_gem_version, latest_gem_version)).to eq([])
		end

		it 'should return no changes if on a version higher than the latest version' do
			versions = %w(0.0.1 1.0.0)
			local_gem_version = ver('1.1.0')
			latest_gem_version = ver('1.0.0')

			expect(StructCore::RefresherHelpers.build_changelist(versions, local_gem_version, latest_gem_version)).to eq([])
		end

		it 'should return no changes if there are no versions listed' do
			versions = %w()
			local_gem_version = ver('1.0.0')
			latest_gem_version = ver('1.0.0')

			expect(StructCore::RefresherHelpers.build_changelist(versions, local_gem_version, latest_gem_version)).to eq([])
		end

		it 'should return one change if one version behind the latest version' do
			versions = %w(0.0.1 1.0.0)
			local_gem_version = ver('0.0.1')
			latest_gem_version = ver('1.0.0')

			expect(StructCore::RefresherHelpers.build_changelist(versions, local_gem_version, latest_gem_version)).to eq(['1.0.0'])
		end

		it 'should return two changes if two versions behind the latest version' do
			versions = %w(0.0.1 0.0.2 1.0.0)
			local_gem_version = ver('0.0.1')
			latest_gem_version = ver('1.0.0')

			expect(StructCore::RefresherHelpers.build_changelist(versions, local_gem_version, latest_gem_version)).to eq(%w(0.0.2 1.0.0))
		end

		it 'should return one change if one versions behind the latest version and higher versions have yet to be released' do
			versions = %w(0.0.1 0.0.2 1.0.0)
			local_gem_version = ver('0.0.1')
			latest_gem_version = ver('0.0.2')

			expect(StructCore::RefresherHelpers.build_changelist(versions, local_gem_version, latest_gem_version)).to eq(%w(0.0.2))
		end
	end

	describe 'determine_changes' do
		it 'should return everything after initial version when specifying initial version' do
			changelog = {}
			changelog['versions'] = {}
			changelog['versions']['0.0.1'] = ['A']
			changelog['versions']['1.0.0'] = ['B']

			expect(StructCore::RefresherHelpers.determine_changes(changelog, ver('0.0.0'), ver('1.0.0'))).to eq("\nStruct 0.0.1\n - A\n\nStruct 1.0.0\n - B")
		end

		it 'should return an empty string when returning the latest version' do
			changelog = {}
			changelog['versions'] = {}
			changelog['versions']['0.0.1'] = ['A']
			changelog['versions']['1.0.0'] = ['B']

			expect(StructCore::RefresherHelpers.determine_changes(changelog, ver('1.0.0'), ver('1.0.0'))).to eq('')
		end

		it 'should return an empty string when returning a version higher than the latest version' do
			changelog = {}
			changelog['versions'] = {}
			changelog['versions']['0.0.1'] = ['A']
			changelog['versions']['1.0.0'] = ['B']

			expect(StructCore::RefresherHelpers.determine_changes(changelog, ver('1.1.0'), ver('1.0.0'))).to eq('')
		end
	end
end
