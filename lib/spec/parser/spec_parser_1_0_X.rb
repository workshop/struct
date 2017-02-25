require 'semantic'

module StructCore
	class Specparser10X
		# @param version [Semantic::Version]
		def can_parse_version(version)
			version.major == 1 && version.minor == 0
		end

		def parse(spec_version, spec_hash, filename)
			valid_configuration_names = []
			configurations = spec_hash['configurations'].map { |name, config|
				unless config != nil and config.key? 'profiles' and config['profiles'].is_a?(Array) and config['profiles'].count > 0
					puts Paint["Warning: Configuration with name '#{name}' was skipped as it was invalid"]
					next nil
				end

				valid_configuration_names << name
				config = Specfile::Configuration.new(name, config['profiles'], config['overrides'] || {}, config['type'])

				unless config.type != nil
					puts Paint["Warning: Configuration with name '#{name}' was skipped as its type did not match one of: debug, release"]
					next nil
				end

				next config
			}.compact
			raise StandardError.new 'Error: Invalid spec file. Project should have at least one configuration' unless configurations.count > 0

			project_base_dir = File.dirname filename
			return Specfile.new(spec_version, [], configurations, [], project_base_dir) unless spec_hash.key? 'targets'
			raise StandardError.new "Error: Invalid spec file. Key 'targets' should be a hash" unless spec_hash['targets'].is_a?(Hash)

			targets = (spec_hash['targets'] || {}).map { |target_name, target_opts|
				parse_target_data(target_name, target_opts, project_base_dir, valid_configuration_names)
			}.compact

			Specfile.new(spec_version, targets, configurations, [], project_base_dir)
		end

		# @return StructCore::Specfile::Target
		def parse_target_data(target_name, target_opts, project_base_dir, valid_config_names)
			# Parse target type
			unless target_opts.key? 'type'
				puts Paint["Warning: Target #{target_name} has no target type. Ignoring target...", :yellow]
				return nil
			end

			type = target_opts['type']
			if type.is_a?(Symbol)
				type = type.to_s
			end
			# : at the start of the type is shorthand for 'com.apple.product-type.'
			if type.start_with? ':'
				type[0] = ''
				raw_type = type
				type = "com.apple.product-type.#{type}"
			else
				raw_type = type
			end

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
			if profiles == nil and target_opts.key? 'platform'
				raw_platform = target_opts['platform']
				# TODO: Add support for 'tvos', 'watchos'
				unless ['ios', 'mac'].include? raw_platform
					puts Paint["Warning: Target #{target_name} specifies unrecognised platform '#{raw_platform}'. Ignoring target...", :yellow]
					return nil
				end

				profiles = [raw_type, "platform:#{raw_platform}"]
			end

			# Parse target configurations
			if target_opts.key? 'configurations'
				unless target_opts['configurations'].is_a?(Hash)
					puts Paint["Warning: Key 'configurations' for target #{target_name} is not a hash. Ignoring target...", :yellow]
					return nil
				end
				configurations = target_opts['configurations'].map do |config_name, config|
					unless valid_config_names.include? config_name
						puts Paint["Warning: Config name #{config_name} for target #{target_name} was not defined in this spec. Ignoring target...", :yellow]
						return nil
					end
					Specfile::Target::Configuration.new(config_name, config, profiles)
				end
			elsif target_opts.key? 'configuration'
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, target_opts['configuration'], profiles)
				}
			else
				puts Paint["Warning: Target #{target_name} has no configuration settings. Ignoring target...", :yellow]
				return nil
			end

			unless configurations.count == valid_config_names.count
				puts Paint["Warning: Missing configurations for target #{target_name}. Expected #{valid_config_names.count}, found: #{configurations.count}. Ignoring target...", :yellow]
				return nil
			end

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

			# Parse target resources
			if target_opts.key? 'i18n-resources'
				target_resources_dir = File.join(project_base_dir, target_opts['i18n-resources'])
			else
				target_resources_dir = target_sources_dir
			end

			# Parse excludes
			if target_opts.key? 'excludes'
				file_excludes = (target_opts['excludes'] || {})['files'] || []
				unless file_excludes.is_a?(Array)
					puts Paint["Warning: Target #{target_name}'s file excludes was not an array. Ignoring file excludes...", :yellow]
					file_excludes = []
				end
			else
				file_excludes = []
			end

			if target_opts.key? 'references'
				raw_references = target_opts['references']
				if raw_references.is_a?(Array)
					references = raw_references.map { |raw_reference|
						if raw_reference.is_a?(Hash)
							project_path = raw_reference['location']

							unless File.exist? File.join(project_base_dir, project_path)
								puts Paint["Warning: Project reference #{project_path} could not be found. Ignoring project...", :yellow]
								next nil
							end

							next Specfile::Target::FrameworkReference.new(project_path, raw_reference)
						else
							# De-symbolise :sdkroot:-prefixed entries
							ref = raw_reference.to_s
							if ref.start_with? 'sdkroot:'
								if ref.end_with? '.framework'
									next Specfile::Target::SystemFrameworkReference.new(raw_reference.sub('sdkroot:', '').sub('.framework', ''))
								else
									next Specfile::Target::SystemLibraryReference.new(raw_reference.sub('sdkroot:', ''))
								end
							else
								next Specfile::Target::TargetReference.new(raw_reference)
							end
						end
					}.compact
				else
					puts Paint["Warning: Key 'references' for target #{target_name} is not an array. Ignoring...", :yellow]
					references = []
				end
			else
				references = []
			end

			options = []
			if target_opts.key? 'options'
				if target_opts['options'].is_a?(Hash)
					if target_opts['options'].key? 'files'
						if target_opts['options']['files'].is_a?(Hash)
							options.unshift *target_opts['options']['files'].map { |glob, fileOpts|
								Specfile::Target::FileOption.new(glob, fileOpts)
							}
						else
							puts Paint["Warning: Key 'files' for target #{target_name}'s options is not a hash. Ignoring...", :yellow]
						end
					end

					if target_opts['options'].key? 'frameworks'
						if target_opts['options']['frameworks'].is_a?(Hash)
							options.unshift *target_opts['options']['frameworks'].map { |name, frameworkOpts|
								Specfile::Target::FrameworkOption.new(name, frameworkOpts)
							}
						else
							puts Paint["Warning: Key 'frameworks' for target #{target_name}'s options is not a hash. Ignoring...", :yellow]
						end
					end
				else
					puts Paint["Warning: Key 'options' for target #{target_name} is not a hash. Ignoring...", :yellow]
				end
			end

			Specfile::Target.new target_name, type, target_sources_dir, configurations, references, options, target_resources_dir, file_excludes
		end
	end
end