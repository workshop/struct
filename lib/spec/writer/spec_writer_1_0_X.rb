require 'semantic'
require 'paint'
require 'yaml'
require 'json'
require_relative '../spec_file'

module Xcodegen
	class Specwriter10X
		# @param version [Semantic::Version]
		def can_write_version(version)
			version.major == 1 && version.minor == 0
		end

		def write_spec(spec, path)

		end

		# @param target [Xcodegen::Specfile::Target]
		# @param path [String]
		def write_target(target, path)
			unless target != nil && target.is_a?(Xcodegen::Specfile::Target)
				raise StandardError.new 'Invalid target object'
			end

			puts Paint["Adding target #{target.name} to project", :green]

			if path.end_with? 'yml' or path.end_with? 'yaml'
				spec_hash = YAML.load_file path
				format = :yml
			elsif path.end_with? 'json'
				spec_hash = JSON.parse File.read(path)
				format = :json
			else
				raise StandardError.new 'Error: Unable to determine file format of project file'
			end

			unless target.configurations.length > 0
				raise StandardError.new 'Error: Invalid target object. Target object must have at least one configuration.'
			end

			profiles = target.configurations.map { |config|
				config.profiles
			}
			unless profiles.all? { |profile| profile == profiles[0] }
				raise StandardError.new 'Error: Invalid target object. Profiles across every configuration must be identical.'
			end

			unless spec_hash.key? 'targets'
				spec_hash['targets'] = {}
			end

			new_target = target_to_hash target
			spec_hash['targets'][target.name] = new_target

			if format == :yml
				File.open(path, 'w+') {|f| f.write spec_hash.to_yaml }
			elsif format == :json
				File.open(path, 'w+') {|f| f.write spec_hash.to_json }
			end
		end

		private
		# @param target [Xcodegen::Specfile::Target]
		def target_to_hash(target)
			target_hash = {}

			target_hash['sources'] = target.source_dir unless (target.source_dir == nil || target.source_dir.length == 0)
			target_hash['i18n-resources'] = target.res_dir unless (target.res_dir == nil || target.res_dir.length == 0)
			target_hash['type'] = target.type.sub('com.apple.product-type.', ':')

			# Try to reconcile configuration blocks into shorthand first.
			# We determine if we should write shorthand with the following rules:
			# - Only two profiles are specified
			# - One of these two profiles is a platform profile
			# - The other of these two profiles is a type profile
			profiles = target.configurations[0].profiles

			platform_profile = profiles.find { |profile|
				profile.start_with? 'platform:'
			}

			expected_profile = target.type.sub('com.apple.product-type.', '')
			type_profile = profiles.find { |profile|
				profile == expected_profile
			}

			if profiles.length == 2 && platform_profile != nil && type_profile != nil
				# If using shorthand, specify the platform
				target_hash['platform'] = platform_profile.sub('platform:', '')
			else
				# Otherwise, specify the full list of configuration profiles
				target_hash['profiles'] = profiles
			end

			# When outputting configuration settings, first determine if every configuration's settings
			# are identical. If this is the case output the singular 'configuration' block, otherwise
			# output the full per-build configuration 'configurations' block.
			settings = target.configurations.map { |config|
				config.settings
			}
			settings_match = settings.all? { |override| override == settings[0] }

			if settings_match
				target_hash['configuration'] = settings[0]
			else
				configurations = {}
				target.configurations.each { |config|
					configurations[config.name] = config.settings
				}

				target_hash['configurations'] = configurations
			end

			references = target.references.map { |ref|
				if ref.is_a? Xcodegen::Specfile::Target::SystemFrameworkReference
					"sdkroot:#{ref.name}.framework"
				elsif ref.is_a? Xcodegen::Specfile::Target::SystemLibraryReference
					"sdkroot:#{ref.name}"
				elsif ref.is_a? Xcodegen::Specfile::Target::FrameworkReference
					obj = {}
					obj.merge! ref.settings
					obj['location'] = ref.project_path
				elsif ref.is_a? Xcodegen::Specfile::Target::TargetReference
					ref.name
				else
					nil
				end
			}.compact

			unless references.length == 0
				target_hash['references'] = references
			end

			unless target.file_excludes.length == 0
				excludes = {}
				excludes['files'] = target.file_excludes

				target_hash['excludes'] = excludes
			end

			target_hash
		end
	end
end