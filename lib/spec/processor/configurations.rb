require_relative 'processor_component'
require_relative '../spec_file'
require_relative '../../utils/defines'
require 'xcodeproj'

module StructCore
	module Processor
		class ConfigurationsComponent
			include ProcessorComponent

			def process(project, dsl = nil)
				output = nil
				output = process_xc_configurations project if structure == :spec
				output = process_spec_configurations project, dsl if structure == :xcodeproj && !dsl.nil?

				output
			end

			def process_xc_configurations(project)
				project.build_configurations.map { |config|
					source = nil

					unless config.base_configuration_reference.nil?
						source = extract_xcconfig_path config.base_configuration_reference, project_dir, directory
					end

					if config.type == :debug
						overrides = config.build_settings.reject { |k, _| XC_DEBUG_SETTINGS_MERGED.include? k }
						next StructCore::Specfile::Configuration.new(config.name, %w(general:debug ios:debug), overrides, 'debug', source)
					elsif config.type == :release
						overrides = config.build_settings.reject { |k, _| XC_RELEASE_SETTINGS_MERGED.include? k }
						next StructCore::Specfile::Configuration.new(config.name, %w(general:release ios:release), overrides, 'release', source)
					else
						raise StandardError.new "Unsupported build configuration type: #{config.type}"
					end
				}
			end

			def process_spec_configurations(project, dsl)
				project.configurations.each { |spec_config|
					config = dsl.add_build_configuration spec_config.name, XC_CONFIGURATION_TYPE_MAP[spec_config.type]
					build_settings = {}

					spec_config.profiles.map { |profile_name|
						[profile_name, File.join(STRUCT_CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
					}.map { |data|
						profile_name, profile_file_name = data
						unless File.exist? profile_file_name
							puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
							next nil
						end

						next YAML.load_file(profile_file_name)
					}.each { |profile_data|
						build_settings = build_settings.merge(profile_data || {})
					}

					build_settings = build_settings.merge spec_config.overrides
					config.build_settings = build_settings
				}
			end
		end
	end
end