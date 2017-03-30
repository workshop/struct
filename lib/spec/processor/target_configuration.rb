require_relative 'processor_component'

module StructCore
	module Processor
		class TargetConfigurationComponent
			include ProcessorComponent

			def process(config, target_dsl = nil, dsl = nil)
				output = nil

				output = process_xc_config config, dsl if structure == :spec && !dsl.nil?
				output = process_spec_config config, target_dsl, dsl if structure == :xcodeproj && !dsl.nil? && !target_dsl.nil?

				output
			end

			# @param config [Xcodeproj::Project::Object::XCBuildConfiguration]
			# @param dsl [Xcodeproj::Project::PBXNativeTarget]
			def process_xc_config(config, dsl)
				type = dsl.product_type.sub 'com.apple.product-type.', ':'
				config_xcconfig_overrides = extract_target_xcconfig_overrides config.base_configuration_reference, @working_directory

				target_sdk = dsl.sdk
				target_sdk = config_xcconfig_overrides['SDKROOT'] unless config_xcconfig_overrides['SDKROOT'].nil?

				profiles = []
				profiles = ['platform:ios', type.sub(':', '')] if target_sdk.include? 'iphoneos'
				profiles = ['platform:mac', type.sub(':', '')] if target_sdk.include? 'macosx'
				profiles = ['platform:tv', type.sub(':', '')] if target_sdk.include? 'appletvos'
				profiles = ['platform:watch', type.sub(':', '')] if target_sdk.include? 'watchos'

				merged_config_settings = extract_target_config_overrides(profiles, config.build_settings)

				path = nil
				path = extract_xcconfig_path config.base_configuration_reference, @working_directory unless config.base_configuration_reference.nil?

				StructCore::Specfile::Target::Configuration.new(
					config.name,
					merged_config_settings,
					profiles,
					path
				)
			end

			# @param config [StructCore::Specfile::Target::Configuration]
			# @param target_dsl [Xcodeproj::Project::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_config(config, target_dsl, dsl)
				build_settings = {}
				config.profiles.map { |profile_name|
					[profile_name, File.join(XC_TARGET_CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
				}.map { |data|
					profile_name, profile_file_name = data
					unless File.exist? profile_file_name
						puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
						next nil
					end

					next YAML.load_file(profile_file_name)
				}.compact.each { |profile_data|
					build_settings = build_settings.merge profile_data
				}

				build_settings = build_settings.merge config.settings

				xc_config = target_dsl.add_build_configuration(config.name, XC_CONFIGURATION_TYPE_MAP[config.name])
				xc_config.build_settings = build_settings

				return if config.source.nil?
				unless File.exist?(File.join(@working_directory, config.source))
					puts Paint["Warning: Configuration #{config.name} source file #{config.source} was not found. The specified xcconfig file will be ignored for this configuration", :yellow]
					return
				end

				config_group = dsl.groups.find { |g| g.display_name == '$config' }
				config_group = dsl.new_group '$config', nil, '<group>' if config_group.nil?
				xc_config.base_configuration_reference = config_group.new_file config.source
			end

			def extract_xcconfig_path(base_configuration_reference, project_dir)
				path = base_configuration_reference.hierarchy_path
				path[0] = '' if path.start_with? '/'

				source_path = File.join(project_dir, path)

				unless File.exist? source_path
					puts Paint["Warning: Unable to locate xcconfig file: #{source_path}. Xcconfig reference will be ignored."]
					return nil
				end

				path
			end

			def extract_target_config_overrides(profiles, build_settings)
				default_settings = profiles.map { |profile_name|
					[profile_name, File.join(XC_TARGET_CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
				}.map { |data|
					profile_name, profile_file_name = data
					unless File.exist? profile_file_name
						puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
						next nil
					end

					next YAML.load_file(profile_file_name)
				}.inject({}) { |settings, next_settings|
					settings.merge next_settings || {}
				}

				build_settings.reject { |k, _| default_settings.include? k }
			end

			def extract_target_xcconfig_overrides(xcconfig_file_ref, project_dir)
				return {} if xcconfig_file_ref.nil?
				xcconfig_file = xcconfig_file_ref.hierarchy_path || ''
				StructCore::XcconfigParser.parse xcconfig_file, project_dir
			end
		end
	end
end