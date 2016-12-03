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
		def self.write(source_spec, filename)
			# Create a clone of the spec to avoid affecting the original referenced object
			# noinspection RubyResolve
			spec = Marshal.load(Marshal.dump(source_spec))
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
			# noinspection RubyResolve
			remaining_targets = Marshal.load(Marshal.dump(spec.targets))
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

			spec.targets.each { |target|
				add_files_to_target target, target_refs[target.name], project, spec.base_dir
			}

			project.save filename
			return nil
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

			target_build_settings = {}
			target.configurations.each { |config|
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
				target_build_settings[config.name] = { :type => spec_configuration_type_map[config.name], :settings => build_settings }
			}

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

		def self.create_group(parent_group, components)
			if components.first == nil
				return parent_group
			end
			group = parent_group[components.first]
			unless group
				group = parent_group.new_group(components.first)
				group.source_tree = '<group>'
				group.path = components.first
			end
			create_group group, components.drop(1)
		end

		# @param target [Xcodegen::Specfile::Target]
		# @param native_target [Xcodeproj::PBXNativeTarget]
		# @param project [Xcodeproj::Project]
		# @param project_working_dir [String]
		def self.add_files_to_target(target, native_target, project, project_directory)
			files = Dir.glob(File.join(target.source_dir, '**', '*')).select { |file|
				!(file.include? '.xcassets/') and
				!(file.include? '.bundle/') and
				!(file.include? '.framework/') and
				!File.directory?(file) and
				!(file.end_with? 'Info.plist') and
				!(file.include? '.lproj')
			}

			if target.res_dir != target.source_dir
				files = files.select { |file|
					!(file.include? target.res_dir)
				}
			end

			rel_source_root = target.source_dir.sub(project_directory, '')
			if rel_source_root.start_with? '/'
				rel_source_root[0] = ''
			end

			source_group = project.new_group(File.basename(target.source_dir), rel_source_root, 'SOURCE_ROOT')

			files.map { |file|
				new_file = file.sub(target.source_dir, '')
				if new_file.start_with? '/'
					new_file[0] = ''
				end
				next new_file
			}.each { |file|
				native_group = file.include?('/') ? create_group(source_group, File.dirname(file).split('/')) : source_group
				native_file = native_group.new_file File.basename(file)
				if file.end_with? '.swift'
					native_target.source_build_phase.files_references << native_file
					native_target.add_file_references [native_file]
				else
					native_target.resources_build_phase.files_references << native_file
					native_target.add_file_references [native_file]
				end
			}

			lfiles = Dir.glob(File.join(target.res_dir, '*.lproj', '**', '*'))
			if lfiles.length > 0
				# Create a virtual path since lproj files go through a layer of indirection before hitting the filesystem
				resource_group = source_group.new_group('$lang', nil, '<group>')
				resource_group.source_tree = 'SOURCE_ROOT'
				lproj_variant_files = []
				lfiles.map { |lfile|
					new_lfile = lfile.sub(target.source_dir, '')
					if new_lfile.start_with? '/'
						new_lfile[0] = ''
					end
					next new_lfile
				}.each { |lfile|
					lfile_components = lfile.split('/')
					lfile_lproj_idx = lfile_components.index{|component|
						component.include? '.lproj'
					}

					lfile_variant_components = []
					lfile_variant_components.unshift *lfile_components
					lfile_variant_components.shift(lfile_lproj_idx + 1)
					lfile_variant_path = lfile_variant_components.join('/')
					unless lproj_variant_files.include? lfile_variant_path
						lproj_variant_files << lfile_variant_path
					end
				}

				lproj_variant_files.each { |lproj_file|
					variant_group = resource_group.new_variant_group(lproj_file, target.res_dir, '<group>')
					# Add all lproj files to the variant group

					Dir.glob(File.join(target.res_dir, '*.lproj', lproj_file)).each { |file|
						native_file = variant_group.new_file(file, '<group>')
						native_target.add_resources [native_file]
					}
				}
			end

		end
	end
end