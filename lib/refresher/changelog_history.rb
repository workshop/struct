require 'semantic'

module StructCore
	module RefresherHelpers
		def self.determine_changes(changelog, local_gem_version, latest_gem_version)
			changelist = build_changelist changelog['versions'].keys, local_gem_version, latest_gem_version
			return '' if changelist.empty?

			changelist.map { |v|
				["\nStruct #{v}"] << changelog['versions'][v].map { |str| " - #{str}" }.join("\n")
			}.join("\n")
		end

		def self.build_changelist(versions, local_gem_version, latest_gem_version)
			return [] if versions.empty?
			return [] if local_gem_version >= latest_gem_version

			versions.map { |v|
				Semantic::Version.new v
			}.select { |v|
				v > local_gem_version && v <= latest_gem_version
			}.sort.map(&:to_s)
		end
	end
end