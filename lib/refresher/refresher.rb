require 'excon'
require 'resolv'
require 'date'
require 'yaml'
require 'semantic'
require 'paint'
require 'tmpdir'
require_relative '../version'

module Xcodegen
	class Refresher
		GIT_CONTENT_REPOSITORY_BASE = 'https://raw.githubusercontent.com/lyptt/xcodegen/master'

		def self.run
			# Silently fail whenever possible and try not to wait too long. Don't want to bug the users!
			unless Refresher.has_internet?
				return
			end

			begin
				local_gem_version = Semantic::Version.new Xcodegen::VERSION
			rescue StandardError => _
				return
			end

			xcodegen_cache_dir = File.join Dir.tmpdir, 'xcodegen-cache'
			unless File.exist? xcodegen_cache_dir
				begin
				Dir.mkdir xcodegen_cache_dir
				rescue StandardError => _
					return
				end
			end

			cached_changelog_path = File.join xcodegen_cache_dir, 'changelog.yml'
			if File.exist? cached_changelog_path
				begin
					changelog = YAML.load_file cached_changelog_path
				rescue StandardError => _
					return
				end

				if changelog == nil || changelog['updated'] == nil
					return
				end

				changed_date = Time.at(changelog['updated']).to_date
				if changed_date == nil
					return
				end

				if changed_date == Time.now.to_date
					print changelog, local_gem_version, xcodegen_cache_dir
					return
				end
			end

			# Keep the timeout super-short. This is a fairly big assumption and needs fine-tuning, but most devs
			# have awesome internet connections, so this should be fine for the most part. Don't want to keep
			# the UI stalling for too long!
			changelog_res = Excon.get("#{GIT_CONTENT_REPOSITORY_BASE}/changelog.yml", :connect_timeout => 5)

			unless changelog_res.status == 200 && changelog_res.body != nil
				return
			end

			begin
				changelog = YAML.load changelog_res.body
			rescue StandardError => _
				return
			end

			changelog['updated'] = Time.now.to_i

			begin
				FileUtils.mkdir_p xcodegen_cache_dir
				FileUtils.rm_rf cached_changelog_path
				File.write cached_changelog_path, changelog.to_yaml
			rescue StandardError => _
				return
			end

			print changelog, local_gem_version, xcodegen_cache_dir
		end

		private
		def self.has_internet?
			dns_resolver = Resolv::DNS.new
			begin
				dns_resolver.getaddress('icann.org')
				return true
			rescue Resolv::ResolvError => _
				return false
			end
		end

		def self.print(changelog, local_gem_version, xcodegen_cache_dir)
			if changelog == nil || changelog['latest'] == nil
				return
			end

			begin
				latest_gem_version = Semantic::Version.new changelog['latest']
			rescue StandardError => _
				return
			end

			unless latest_gem_version.major > local_gem_version.major ||
				(latest_gem_version.major == local_gem_version.major && latest_gem_version.minor > local_gem_version.minor) ||
				(latest_gem_version.major == local_gem_version.major && latest_gem_version.minor == local_gem_version.minor && latest_gem_version.patch > local_gem_version.patch)
				return
			end

			# It's now confirmed the user is not on the latest version. Yay!
			puts Paint["\nThere's a newer version of Xcodegen out! Why not give it a try?\n"\
						  "You're on #{local_gem_version.to_s}, and the latest is #{latest_gem_version.to_s}.\n\n"\
						  "I'd love to get your feedback on Xcodegen. Feel free to ping me\n"\
						  "on Twitter @lyptt, or file a github issue if there's something that\n"\
						  "can be improved at https://github.com/lyptt/xcodegen/issues.\n", :green]

			if changelog['versions'] == nil
				return
			end

			if changelog['versions'][latest_gem_version.to_s] == nil
				return
			end

			puts Paint["What's new:\n-----------", :yellow]
			puts Paint[changelog['versions'][latest_gem_version.to_s].map{ |str| " -  #{str}" }.join("\n"), :yellow]
		end
	end
end
