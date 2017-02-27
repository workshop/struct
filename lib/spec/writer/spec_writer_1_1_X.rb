require 'semantic'
require 'paint'
require 'yaml'
require 'json'
require_relative '../spec_file'

# TODO: Refactor this once we have integration tests
# rubocop:disable all
module StructCore
	class Specwriter11X
		# @param version [Semantic::Version]
		def can_write_version(version)
			version.major == 1 && version.minor == 1
		end

		# @param spec [StructCore::Specfile]
		# @param path [String]
		def write_spec(spec, path)
			unless spec != nil && spec.is_a?(StructCore::Specfile)
				raise StandardError.new 'Invalid configuration object'
			end

			if path.end_with? 'yml' or path.end_with? 'yaml'
				format = :yml
			elsif path.end_with? 'json'
				format = :json
			else
				raise StandardError.new 'Error: Unable to determine file format of project file'
			end

			puts Paint["Writing spec to: #{path}", :green]

			project_directory = File.dirname(path)

			spec_hash = {}
			spec_hash['version'] = '1.1.0'

			configurations = {}
			spec.configurations.each { |config|
				configurations[config.name] = configuration_to_hash config
			}

			spec_hash['configurations'] = configurations

			targets = {}
			spec.targets.each { |target|
				targets[target.name] = target_to_hash target, project_directory
			}

			spec_hash['targets'] = targets

			if format == :yml
				File.open(path, 'w+') {|f| f.write spec_hash.to_yaml }
			elsif format == :json
				File.open(path, 'w+') {|f| f.write spec_hash.to_json }
			end
		end

		# @param configuration [StructCore::Specfile::Configuration]
		# @param path [String]
		def write_configuration(configuration, path)
			unless configuration != nil && configuration.is_a?(StructCore::Specfile::Configuration)
				raise StandardError.new 'Invalid configuration object'
			end

			puts Paint["Adding configuration #{configuration.name} to project", :green]

			if path.end_with? 'yml' or path.end_with? 'yaml'
				spec_hash = YAML.load_file path
				format = :yml
			elsif path.end_with? 'json'
				spec_hash = JSON.parse File.read(path)
				format = :json
			else
				raise StandardError.new 'Error: Unable to determine file format of project file'
			end

			unless spec_hash.key? 'configurations'
				spec_hash['configurations'] = {}
			end

			spec_hash['configurations'][configuration.name] = configuration_to_hash configuration

			if format == :yml
				File.open(path, 'w+') {|f| f.write spec_hash.to_yaml }
			elsif format == :json
				File.open(path, 'w+') {|f| f.write spec_hash.to_json }
			end
		end

		# @param target [StructCore::Specfile::Target]
		# @param path [String]
		def write_target(target, path)
			unless target != nil && target.is_a?(StructCore::Specfile::Target)
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

			new_target = target_to_hash target, File.dirname(path)
			spec_hash['targets'][target.name] = new_target

			if format == :yml
				File.open(path, 'w+') {|f| f.write spec_hash.to_yaml }
			elsif format == :json
				File.open(path, 'w+') {|f| f.write spec_hash.to_json }
			end
		end

		private
		# @param configuration [StructCore::Specfile::Configuration]
		def configuration_to_hash(configuration)
			config_hash = {}
			config_hash['profiles'] = configuration.profiles

			unless configuration.overrides == nil || configuration.overrides.keys.length == 0
				config_hash['overrides'] = configuration.overrides
			end

			unless configuration.raw_type == nil
				config_hash['type'] = configuration.raw_type
			end

			config_hash
		end

		# @param target [StructCore::Specfile::Target]
		def target_to_hash(target, project_directory)
			target_hash = {}

			unless target.source_dir == nil || target.source_dir.length == 0
				target_hash['sources'] = target.source_dir.map { |dir| dir.sub("#{project_directory}/", '') }
			end

			unless target.res_dir == nil || target.res_dir.length == 0
				target_hash['i18n-resources'] = target.res_dir.map { |dir| dir.sub("#{project_directory}/", '') }
			end

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
				if ref.is_a? StructCore::Specfile::Target::SystemFrameworkReference
					"sdkroot:#{ref.name}.framework"
				elsif ref.is_a? StructCore::Specfile::Target::SystemLibraryReference
					"sdkroot:#{ref.name}"
				elsif ref.is_a? StructCore::Specfile::Target::FrameworkReference
					obj = {}
					obj.merge! ref.settings
					obj['location'] = ref.project_path
				elsif ref.is_a? StructCore::Specfile::Target::TargetReference
					ref.target_name
				elsif ref.is_a? StructCore::Specfile::Target::LocalFrameworkReference
					obj = {}
					obj.merge!(ref.settings || {})

					local_path = ref.framework_path.sub(project_directory, '')
					local_path[0] = '' if local_path.start_with? '/'
					obj['location'] = local_path
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
# rubocop:enable all