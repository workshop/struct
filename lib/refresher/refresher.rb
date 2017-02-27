require 'excon'
require 'resolv'
require 'date'
require 'yaml'
require 'semantic'
require 'paint'
require 'tmpdir'
require_relative '../version'

module StructCore
	class Refresher
		GIT_CONTENT_REPOSITORY_BASE = 'https://raw.githubusercontent.com/lyptt/xcodegen/master'.freeze

		# There's not much sense refactoring this to be tiny methods.
		# rubocop:disable Metrics/AbcSize
		# rubocop:disable Metrics/PerceivedComplexity
		def self.run
			# Silently fail whenever possible and try not to wait too long. Don't want to bug the users!
			return unless Refresher.internet?

			begin
				local_gem_version = Semantic::Version.new StructCore::VERSION
				struct_cache_dir = File.join Dir.tmpdir, 'struct-cache'
				Dir.mkdir struct_cache_dir unless File.exist? struct_cache_dir
			rescue StandardError => _
				return
			end

			cached_changelog_path = File.join struct_cache_dir, 'changelog.yml'
			if File.exist? cached_changelog_path
				begin
					changelog = YAML.load_file cached_changelog_path
				rescue StandardError => _
					return
				end

				return if changelog.nil? || changelog['updated'].nil?

				changed_date = Time.at(changelog['updated']).to_date
				return if changed_date.nil?

				if changed_date == Time.now.to_date
					print changelog, local_gem_version
					return
				end
			end

			# Keep the timeout super-short. This is a fairly big assumption and needs fine-tuning, but most devs
			# have awesome internet connections, so this should be fine for the most part. Don't want to keep
			# the UI stalling for too long!
			changelog_res = Excon.get("#{GIT_CONTENT_REPOSITORY_BASE}/changelog.yml", connect_timeout: 5)

			return unless changelog_res.status == 200 && !changelog_res.body.nil?

			begin
				changelog = YAML.safe_load changelog_res.body
				changelog['updated'] = Time.now.to_i
				FileUtils.mkdir_p struct_cache_dir
				FileUtils.rm_rf cached_changelog_path
				File.write cached_changelog_path, changelog.to_yaml
			rescue StandardError => _
				return
			end

			print changelog, local_gem_version
		end
		# rubocop:enable Metrics/AbcSize
		# rubocop:enable Metrics/PerceivedComplexity

		def self.internet?
			dns_resolver = Resolv::DNS.new
			begin
				dns_resolver.getaddress('icann.org')
				return true
			rescue Resolv::ResolvError => _
				return false
			end
		end

		private_class_method def self.out_of_date?(latest_gem_version, local_gem_version)
			latest_gem_version.major > local_gem_version.major ||
				(latest_gem_version.major == local_gem_version.major && latest_gem_version.minor > local_gem_version.minor) ||
				(latest_gem_version.major == local_gem_version.major && latest_gem_version.minor == local_gem_version.minor && latest_gem_version.patch > local_gem_version.patch)
		end

		private_class_method def self.print(changelog, local_gem_version)
			return if changelog.nil? || changelog['latest'].nil?

			begin
				latest_gem_version = Semantic::Version.new changelog['latest']
			rescue StandardError => _
				return
			end

			return unless out_of_date? latest_gem_version, local_gem_version

			# It's now confirmed the user is not on the latest version. Yay!
			puts Paint["\nThere's a newer version of Struct out! Why not give it a try?\n"\
						  "You're on #{local_gem_version}, and the latest is #{latest_gem_version}.\n\n"\
						  "I'd love to get your feedback on Struct. Feel free to ping me\n"\
						  "on Twitter @lyptt, or file a github issue if there's something that\n"\
						  "can be improved at https://github.com/lyptt/xcodegen/issues.\n", :green]

			return if changelog['versions'].nil? || changelog['versions'][latest_gem_version.to_s].nil?

			puts Paint["What's new:\n-----------", :yellow]
			puts Paint[changelog['versions'][latest_gem_version.to_s].map { |str| " -  #{str}" }.join("\n"), :yellow]
		end
	end
end
