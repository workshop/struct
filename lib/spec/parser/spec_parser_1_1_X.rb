require 'semantic'

module StructCore
	class Specparser11X
		# @param version [Semantic::Version]
		def can_parse_version(version)
			version.major == 1 && version.minor == 1
		end

		def parse(spec_version, spec_hash, filename)
			valid_configuration_names = []
			configurations = spec_hash['configurations'].map { |name, config|
				unless config&.key? 'profiles' and config['profiles'].is_a?(Array) and config['profiles'].count > 0
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

			variants = (spec_hash['variants'] || {}).map { |variant_name, variant_targets|
				parse_variant_data(variant_name, variant_targets, project_base_dir, valid_configuration_names)
			}.compact

			if variants.select { |variant| variant.name == '$base' }.count == 0
				variants.push StructCore::Specfile::Variant.new('$base', [], false)
			end

			Specfile.new(spec_version, targets, configurations, variants, project_base_dir)
		end

		def parse_variant_data(variant_name, variant_targets, project_base_dir, valid_configuration_names)
			if (variant_name || '').empty? and variant_targets == nil
				return nil
			end

			abstract = false
			targets = []

			(variant_targets || {}).each { |key, value|
				if key == 'abstract'
					abstract = true
				else
					targets.unshift(parse_variant_target_data(key, value, project_base_dir, valid_configuration_names))
				end
			}

			StructCore::Specfile::Variant.new(variant_name, targets, abstract)
		end

		def parse_variant_target_data(target_name, target_opts, project_base_dir, valid_config_names)
			type = nil
			raw_type = nil
			# Parse target type
			if target_opts.key? 'type'
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
			end

			# Parse target platform/type/profiles into a profiles list
			profiles = []
			if target_opts.key? 'profiles'
				if target_opts['profiles'].is_a?(Array)
					profiles = target_opts['profiles']
				else
					puts Paint["Warning: Key 'profiles' for variant override #{target_name} is not an array. Ignoring...", :yellow]
				end
			elsif profiles == nil and target_opts.key? 'platform'
				raw_platform = target_opts['platform']
				profiles = [raw_type, "platform:#{raw_platform}"].compact
			end

			# Parse target configurations
			if target_opts.key? 'configurations'
				if target_opts['configurations'].is_a?(Hash)
					configurations = target_opts['configurations'].map {|config_name, config|
						if valid_config_names.include? config_name
							next nil
						end
						Specfile::Target::Configuration.new(config_name, config, profiles)
					}.compact
				end
			elsif target_opts.key? 'configuration'
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, target_opts['configuration'], profiles)
				}
			end

			# Parse target sources
			if target_opts.key? 'sources'
				if target_opts['sources'].is_a?(Array)
					target_sources_dir = target_opts['sources'].map { |src| File.join(project_base_dir, src) }
				else
					target_sources_dir = [File.join(project_base_dir, target_opts['sources'])]
				end
				target_sources_dir = target_sources_dir.select { |dir| Dir.exist? dir }
				unless target_sources_dir.count > 0
					target_sources_dir = nil
				end
			end

			# Parse target resources
			if target_opts.key? 'i18n-resources'
				target_resources_dir = File.join(project_base_dir, target_opts['i18n-resources'])
			else
				target_resources_dir = nil
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
							path = raw_reference['location']

							unless File.exist? File.join(project_base_dir, path)
								puts Paint["Warning: Reference #{path} could not be found. Ignoring...", :yellow]
								next nil
							end

							if raw_reference['frameworks'] == nil
								next Specfile::Target::LocalFrameworkReference.new(path, raw_reference)
							else
								next Specfile::Target::FrameworkReference.new(path, raw_reference)
							end
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
				else
					puts Paint["Warning: Key 'options' for target #{target_name} is not a hash. Ignoring...", :yellow]
				end
			end

			Specfile::Target.new target_name, type, target_sources_dir, configurations, references, options, target_resources_dir, file_excludes
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
				puts Paint["Warning: Target #{target_name} contained no valid sources directories. Ignoring target...", :yellow]
				return nil
			end

			if target_opts.key? 'sources'
				if target_opts['sources'].is_a?(Array)
					target_sources_dir = target_opts['sources'].map { |src| File.join(project_base_dir, src) }
				else
					target_sources_dir = [File.join(project_base_dir, target_opts['sources'])]
				end
				target_sources_dir = target_sources_dir.select { |dir| Dir.exist? dir }
				unless target_sources_dir.count > 0
					target_sources_dir = nil
				end
			end
			if target_sources_dir == nil
				puts Paint["Warning: Target #{target_name} contained no valid sources directories. Ignoring target...", :yellow]
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
							path = raw_reference['location']

							unless File.exist? File.join(project_base_dir, path)
								puts Paint["Warning: Reference #{path} could not be found. Ignoring...", :yellow]
								next nil
							end

							if raw_reference['frameworks'] == nil
								next Specfile::Target::LocalFrameworkReference.new(path, raw_reference)
							else
								next Specfile::Target::FrameworkReference.new(path, raw_reference)
							end
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
				else
					puts Paint["Warning: Key 'options' for target #{target_name} is not a hash. Ignoring...", :yellow]
				end
			end

			# Parse target run scripts
			if target_opts.key? 'scripts' and target_opts['scripts'].is_a?(Array)
				scripts = target_opts['scripts'].map { |s|
					next nil if s.start_with? '/' # Script file should be relative to project
					next nil unless File.exist? File.join(project_base_dir, s)
					Specfile::Target::RunScript.new s
				}.compact
			else
				scripts = []
			end

			Specfile::Target.new target_name, type, target_sources_dir, configurations, references, options, target_resources_dir, file_excludes, run_scripts=scripts
		end
	end
end