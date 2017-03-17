require 'semantic'

module StructCore
	class Specparser10X
		# @param version [Semantic::Version]
		def can_parse_version(version)
			version.major == 1 && version.minor.zero?
		end

		def parse(spec_version, spec_hash, filename)
			valid_configuration_names = []
			configurations = parse_configurations spec_hash, valid_configuration_names
			raise StandardError.new 'Error: Invalid spec file. Project should have at least one configuration' unless configurations.count > 0

			project_base_dir = File.dirname filename
			return Specfile.new(spec_version, [], configurations, [], project_base_dir) unless spec_hash.key? 'targets'
			raise StandardError.new "Error: Invalid spec file. Key 'targets' should be a hash" unless spec_hash['targets'].is_a?(Hash)

			targets = (spec_hash['targets'] || {}).map { |target_name, target_opts|
				next nil if target_opts.nil?
				parse_target_data(target_name, target_opts, project_base_dir, valid_configuration_names)
			}.compact

			Specfile.new(spec_version, targets, configurations, [], project_base_dir)
		end

		# @return Array<StructCore::Specfile::Configuration>
		def parse_configurations(spec_hash, valid_configuration_names)
			return [] unless spec_hash.key? 'configurations'
			return [] unless spec_hash['configurations'].is_a? Hash

			spec_hash['configurations'].map { |name, config|
				unless config.is_a?(Hash)
					puts Paint["Warning: Configuration with name '#{name}' was skipped as it was invalid"]
					next nil
				end

				if config.nil? || !config.key?('profiles') || !config['profiles'].is_a?(Array) || config['profiles'].empty?
					puts Paint["Warning: Configuration with name '#{name}' was skipped as it was invalid"]
					next nil
				end

				overrides = parse_config_overrides config, name
				type = parse_config_type config, name

				valid_configuration_names << name
				config = Specfile::Configuration.new(name, config['profiles'], overrides || {}, type)

				if config.type.nil?
					puts Paint["Warning: Configuration with name '#{name}' was skipped as its type did not match one of: debug, release"]
					next nil
				end

				next config
			}.compact
		end

		def parse_config_overrides(config, name)
			overrides = config['overrides'] || {}

			unless overrides.is_a?(Hash)
				overrides = {}
				puts Paint["Warning: Configuration with name '#{name}' had improperly formatted overrides, overrides were skipped for this configuration block"]
			end

			overrides
		end

		def parse_config_type(config, name)
			type = config['type']
			unless type.nil? || type.is_a?(String)
				type = nil
				puts Paint["Warning: Configuration with name '#{name}' had an improperly formatted type, the type was skipped for this configuration block"]
			end

			type
		end

		def parse_target_type(target_opts)
			# Parse target type
			return nil unless target_opts.key? 'type'

			type = target_opts['type']
			type = type.to_s if type.is_a?(Symbol)
			# : at the start of the type is shorthand for 'com.apple.product-type.'
			if type.start_with? ':'
				type[0] = ''
				raw_type = type
				type = "com.apple.product-type.#{type}"
			else
				raw_type = type
			end

			[raw_type, type]
		end

		def parse_target_profiles_platform(target_opts, raw_type, target_name)
			# Parse target platform/type/profiles into a profiles list
			profiles = nil
			if target_opts.key? 'profiles'
				if target_opts['profiles'].is_a?(Array)
					profiles = target_opts['profiles']
				else
					puts Paint["Warning: Key 'profiles' for target #{target_name} is not an array. Ignoring...", :yellow]
				end
			end

			# Search for platform only if profiles weren't already defined
			if profiles.nil? && target_opts.key?('platform')
				raw_platform = target_opts['platform']
				unless %w(ios mac).include? raw_platform
					puts Paint["Warning: Target #{target_name} specifies unrecognised platform '#{raw_platform}'. Ignoring target...", :yellow]
					return nil
				end

				profiles = [raw_type, "platform:#{raw_platform}"]
			end

			profiles
		end

		def parse_target_configurations(target_opts, valid_config_names, profiles, target_name)
			# Parse target configurations
			if target_opts.key? 'configurations'
				unless target_opts['configurations'].is_a?(Hash)
					puts Paint["Warning: Key 'configurations' for target #{target_name} is not a hash. Ignoring target...", :yellow]
					return nil
				end
				configurations = target_opts['configurations'].map do |config_name, overrides|
					unless valid_config_names.include? config_name
						puts Paint["Warning: Config name #{config_name} for target #{target_name} was not defined in this spec. Ignoring target...", :yellow]
						return nil
					end
					Specfile::Target::Configuration.new(config_name, overrides, profiles)
				end
			elsif target_opts.key? 'configuration'
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, target_opts['configuration'], profiles)
				}
			else
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, {}, profiles)
				}
			end

			configurations
		end

		def parse_target_sources_dir(target_opts, project_base_dir, target_name)
			# Parse target sources
			unless target_opts.key? 'sources'
				puts Paint["Warning: Target #{target_name} has no sources directory. Ignoring target...", :yellow]
				return nil
			end

			target_sources_dir = File.join(project_base_dir, target_opts['sources'])
			unless Dir.exist? target_sources_dir
				puts Paint["Warning: Target #{target_name}'s sources directory does not exist. Ignoring target...", :yellow]
				return nil
			end

			target_sources_dir
		end

		def parse_target_resources_dir(target_opts, project_base_dir, target_sources_dir)
			# Parse target resources
			target_resources_dir = target_sources_dir

			if target_opts.key? 'i18n-resources'
				target_resources_dir = File.join(project_base_dir, target_opts['i18n-resources'])
			end

			target_resources_dir
		end

		def parse_target_excludes(target_opts, target_name)
			# Parse excludes
			if target_opts.key?('excludes') && !target_opts['excludes'].nil? && target_opts['excludes'].is_a?(Hash)
				file_excludes = target_opts['excludes']['files'] || []
				unless file_excludes.is_a?(Array)
					puts Paint["Warning: Target #{target_name}'s file excludes was not an array. Ignoring file excludes...", :yellow]
					file_excludes = []
				end
			else
				file_excludes = []
			end

			file_excludes
		end

		def parse_target_references(target_opts, project_base_dir, target_name)
			return [] unless target_opts.key?('references')
			raw_references = target_opts['references']

			unless raw_references.is_a?(Array)
				puts Paint["Warning: Key 'references' for target #{target_name} is not an array. Ignoring...", :yellow]
				return []
			end

			raw_references.map { |raw_reference|
				if raw_reference.is_a?(Hash)
					unless raw_reference.key?('location')
						puts Paint['Warning: Invalid project reference detected. Ignoring...', :yellow]
						next nil
					end

					project_path = raw_reference['location']

					unless File.exist? File.join(project_base_dir, project_path)
						puts Paint["Warning: Project reference #{project_path} could not be found. Ignoring...", :yellow]
						next nil
					end

					next Specfile::Target::FrameworkReference.new(project_path, raw_reference)
				else
					# De-symbolise :sdkroot:-prefixed entries
					ref = raw_reference.to_s

					next Specfile::Target::TargetReference.new(raw_reference) unless ref.start_with? 'sdkroot:'

					next Specfile::Target::SystemFrameworkReference.new(raw_reference.sub('sdkroot:', '').sub('.framework', '')) if ref.end_with? '.framework'
					next Specfile::Target::SystemLibraryReference.new(raw_reference.sub('sdkroot:', ''))
				end
			}.compact
		end

		# @return StructCore::Specfile::Target
		def parse_target_data(target_name, target_opts, project_base_dir, valid_config_names)
			type, raw_type = parse_target_type target_opts
			if type.nil?
				puts Paint["Warning: Target #{target_name} has no target type. Ignoring target...", :yellow]
				return nil
			end

			profiles = parse_target_profiles_platform target_opts, raw_type, target_name

			configurations = parse_target_configurations target_opts, valid_config_names, profiles, target_name
			return nil if configurations.nil?

			unless configurations.count == valid_config_names.count
				puts Paint["Warning: Missing configurations for target #{target_name}. Expected #{valid_config_names.count}, found: #{configurations.count}. Ignoring target...", :yellow]
				return nil
			end

			target_sources_dir = parse_target_sources_dir target_opts, project_base_dir, target_name
			return nil if target_sources_dir.nil?

			target_resources_dir = parse_target_resources_dir target_opts, project_base_dir, target_sources_dir
			return nil if target_resources_dir.nil?

			file_excludes = parse_target_excludes target_opts, target_name
			references = parse_target_references target_opts, project_base_dir, target_name

			Specfile::Target.new target_name, type, target_sources_dir, configurations, references, [], target_resources_dir, file_excludes
		end

		private :parse_configurations
		private :parse_config_overrides
		private :parse_config_type
		private :parse_target_type
		private :parse_target_profiles_platform
		private :parse_target_configurations
		private :parse_target_sources_dir
		private :parse_target_resources_dir
		private :parse_target_excludes
		private :parse_target_references
		private :parse_target_data
	end
end