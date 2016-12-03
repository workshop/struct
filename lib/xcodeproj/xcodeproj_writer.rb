require 'xcodeproj'
require 'yaml'
require 'paint'
require_relative '../spec/spec_file'

module Xcodegen
	class XcodeprojWriter
		CONFIG_PROFILE_PATH = File.join(__dir__, '..', '..', 'res', 'config_profiles')
		TARGET_CONFIG_PROFILE_PATH = File.join(__dir__, '..', '..', 'res', 'target_config_profiles')

		# Sourced from Cocoapods:Xcodeproj project. This should be kept up to date with that gem.
		PRODUCT_TYPE_UTI_INV = {
			'com.apple.product-type.application' => :application,
			'com.apple.product-type.framework' => :framework,
			'com.apple.product-type.library.dynamic' => :dynamic_library,
			'com.apple.product-type.library.static' => :static_library,
			'com.apple.product-type.bundle' => :bundle,
			'com.apple.product-type.bundle.unit-test' => :unit_test_bundle,
			'com.apple.product-type.bundle.ui-testing' => :ui_test_bundle,
			'com.apple.product-type.app-extension' => :app_extension,
			'com.apple.product-type.tool' => :command_line_tool,
			'com.apple.product-type.application.watchapp' => :watch_app,
			'com.apple.product-type.application.watchapp2' => :watch2_app,
			'com.apple.product-type.watchkit-extension' => :watch_extension,
			'com.apple.product-type.watchkit2-extension' => :watch2_extension,
			'com.apple.product-type.tv-app-extension' => :tv_extension,
			'com.apple.product-type.application.messages' => :messages_application,
			'com.apple.product-type.app-extension.messages' => :messages_extension,
			'com.apple.product-type.app-extension.messages-sticker-pack' => :sticker_pack,
			'com.apple.product-type.xpc-service' => :xpc_service
		}.freeze

		# @param spec [Xcodegen::Specfile]
		# @param filename [String]
		def self.write(spec, filename)
			spec_xcodeproj_type_map = {}
			spec_xcodeproj_type_map['debug'] = :debug
			spec_xcodeproj_type_map['release'] = :release
			spec_configuration_type_map = {}

			unless spec != nil and spec.is_a? Xcodegen::Specfile
				raise StandardError.new 'Invalid spec file'
			end

			unless spec.configurations.length > 0
				raise StandardError.new 'Spec must have at least one configuration'
			end

			# Create the new project file and clear out any defaults we don't need
			project = Xcodeproj::Project.new(filename)
			project.build_configurations.clear

			# Create all of the project-level configurations
			spec.configurations.each { |spec_config|
				config = project.add_build_configuration spec_config.name, spec_xcodeproj_type_map[spec_config.type]
				spec_configuration_type_map[spec_config.name] = spec_config.type
				build_settings = {}

				spec_config.profiles.map { |profile_name|
					[profile_name, File.join(CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
				}.map { |data|
					profile_name, profile_file_name = data
					unless File.exist? profile_file_name
						puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
						next nil
					end

					next YAML.load_file(profile_file_name)
				}.each { |profile_data|
					build_settings = build_settings.merge (profile_data || {})
				}

				build_settings = build_settings.merge spec_config.overrides
				config.build_settings = build_settings
			}

			# Update build configuration list's defaultConfigurationName to be the first configuration in our spec
			project.build_configuration_list.default_configuration_name = spec.configurations[0].name

			# Create all of the targets
			target_refs = {}
			remaining_targets = spec.targets
			iterations_remaining = remaining_targets.count
			remaining_targets_removed = 0

			# As we don't know which unreferenced targets are where, attempt to create each target in turn
			# If a target cannot be created due to its reference not existing in target_refs, it will be skipped
			# until the next cycle.
			#
			# If an entire cycle passes without an element being removed from remaining_targets, it is assumed we
			# are encountering a circular reference, and in that scenario we break early.
			while remaining_targets.length > 0
				target = remaining_targets.first
				if target == nil
					break
				end

				native_target = add_target target, project, target_refs, spec_configuration_type_map
				if native_target != nil
					target_refs[target.name] = native_target
					remaining_targets_removed = remaining_targets_removed + 1
					remaining_targets.shift
				end

				iterations_remaining = iterations_remaining - 1
				if iterations_remaining == 0
					if remaining_targets_removed == 0
						raise StandardError.new 'Circular target references were found in spec, aborting'
					else
						iterations_remaining = remaining_targets.length
						remaining_targets_removed = 0
					end
				end
				remaining_targets.rotate!
			end

			return project
		end

		# @param target [Xcodegen::Specfile::Target]
		# @param project [Xcodeproj::Project]
		# @param target_refs [Hash<String, Xcodeproj::PBXNativeTarget>]
		# @param spec_configuration_type_map [Hash<String, String>]
		# @return [Xcodeproj::PBXNativeTarget]
		def self.add_target(target, project, target_refs, spec_configuration_type_map)
			requested_target_refs = target.references.select { |ref| ref.is_a? Xcodegen::Specfile::Target::TargetReference }
			target_references = requested_target_refs.map { |ref|
				unless target_refs.has_key? ref.target_name
					return nil
				end

				next target_refs[ref.target_name]
			}.compact

			if requested_target_refs.length != target_references.length
				puts Paint["Warning: Not all target references could be resolved for target: '#{target.name}'.", :yellow]
			end

			target_build_settings = Hash[target.configurations.map { |config|
				build_settings = {}
				config.profiles.map { |profile_name|
					[profile_name, File.join(TARGET_CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
				}.map { |data|
					profile_name, profile_file_name = data
					unless File.exist? profile_file_name
						puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
						next nil
					end

					next YAML.load_file(profile_file_name)
				}.each { |profile_data|
					build_settings = build_settings.merge (profile_data || {})
				}

				build_settings = build_settings.merge config.settings
				next ["#{config.name}", { :type => spec_configuration_type_map[config.name], :settings => build_settings }]
			}]

			sdk = target_build_settings[target_build_settings.keys.first][:settings]['SDKROOT']

			unless sdk != nil
				puts Paint["Warning: SDKROOT not found in configuration for target: '#{target.name}'. Ignoring...", :yellow]
				return nil
			end

			if sdk.include? 'iphoneos'
				platform = :ios
			elsif sdk.include? 'macosx'
				platform = :osx
			elsif sdk.include? 'appletvos'
				platform = :tvos
			elsif sdk.include? 'watchos'
				platform = :watchos
			else
				puts Paint["Warning: SDKROOT #{build_settings['SDKROOT']} not recognised in configuration for target: '#{target.name}'. Ignoring...", :yellow]
				return nil
			end

			native_target = project.new_target PRODUCT_TYPE_UTI_INV[target.type], target.name, platform, nil, nil, :swift
			native_target.build_configurations.clear
			target_build_settings.each { |name, data|
				config = native_target.add_build_configuration(name, data[:type])
				config.build_settings = data[:settings]
			}

			target_references.each { |native_ref|
				native_target.add_dependency native_ref
			}

			return native_target
		end
	end
end