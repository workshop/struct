require 'xcodeproj'
require 'yaml'
require 'paint'
require 'deep_clone'
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
		# @param destination [String]
		def self.write(source_spec, destination)
			# Create a clone of the spec to avoid affecting the original referenced object
			# noinspection RubyResolve
			spec = Marshal.load(Marshal.dump(source_spec))

			unless spec != nil and spec.is_a? Xcodegen::Specfile
				raise StandardError.new 'Invalid spec file'
			end

			unless spec.configurations.length > 0
				raise StandardError.new 'Spec must have at least one configuration'
			end

			if spec.variants.count == 0
				write_xcodeproj spec, File.join(destination, 'project.xcodeproj')
			else
				# Generate a derived spec for each variant and write out the variants
				specs = spec.variants.map { |variant|
					next nil if variant.abstract

					variant_targets = DeepClone.clone variant.targets
					spec_targets = DeepClone.clone spec.targets

					variant_targets.each { |target|
						spec_target = spec_targets.find { |st| st.name == target.name }
						next if spec_target == nil

						spec_target.source_dir = spec_target.source_dir.unshift(*target.source_dir).uniq
						spec_target.res_dir = spec_target.res_dir.unshift(*target.res_dir).uniq
						spec_target.file_excludes = [].unshift(*spec_target.file_excludes).unshift(*target.file_excludes).uniq

						target.configurations.each { |configuration|
							spec_config = spec_target.configurations.find { |sc| sc.name == configuration.name }
							spec_config.settings.merge! configuration.settings
							spec_config.profiles = [].unshift(*configuration.profiles).unshift(*spec_config.profiles).uniq
						}

						spec_target.file_excludes = [].unshift(*spec_target.file_excludes).unshift(*target.file_excludes)
						spec_target.options = [].unshift(*spec_target.options).unshift(*target.options)
						spec_target.references = [].unshift(*spec_target.references).unshift(*target.references)
					}

					[variant.name, Xcodegen::Specfile.new(spec.version, spec_targets, spec.configurations, [], spec.base_dir)]
				}.compact.to_h

				specs.each { |name, variant_spec|
					if name == '$base'
						write_xcodeproj variant_spec, File.join(destination, 'project.xcodeproj')
					else
						write_xcodeproj variant_spec, File.join(destination, "#{name.downcase.gsub(/[^0-9a-z]/, '')}.xcodeproj")
					end
				}
			end
		end

		# @param target [Xcodegen::Specfile::Target]
		# @param project [Xcodeproj::Project]
		# @param target_refs [Hash<String, Xcodeproj::PBXNativeTarget>]
		# @param spec_configuration_type_map [Hash<String, String>]
		# @return [Xcodeproj::PBXNativeTarget]
		def self.add_target(target, project, target_refs, spec_configuration_type_map)
			requested_target_refs = target.references.select { |ref| ref.is_a? Xcodegen::Specfile::Target::TargetReference }
			target_references = requested_target_refs.map { |ref|
				# If the referenced target has not been added to the project yet, skip this target for now
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

			requested_sys_framework_refs = target.references
				.select { |ref| ref.is_a? Xcodegen::Specfile::Target::SystemFrameworkReference }
				.map { |ref| ref.name }
				.select { |ref| ref != 'Foundation' } # Filter out Foundation as it's already added by default
			native_target.add_system_framework requested_sys_framework_refs

			requested_sys_library_refs = target.references
				.select { |ref| ref.is_a? Xcodegen::Specfile::Target::SystemLibraryReference }
				.map { |ref| ref.name }
			native_target.add_system_library requested_sys_library_refs

			subproj_group = project.frameworks_group.groups.find { |g| g.display_name == '$subproj' }
			if subproj_group == nil
				 subproj_group = project.frameworks_group.new_group '$subproj', nil, '<group>'
			end
			framework_group = project.frameworks_group.groups.find { |group| group.display_name == '$local' }
			if framework_group == nil
				framework_group = project.frameworks_group.new_group '$local', nil, '<group>'
			end
			target.references.select { |ref| ref.is_a? Xcodegen::Specfile::Target::FrameworkReference }.each { |f|
				subproj = subproj_group.new_file f.project_path
				remote_project = Xcodeproj::Project.open f.project_path

				f.settings['frameworks'].map { |f_opts|
					remote_target = remote_project.targets.select { |t|
						t.product_reference.path == f_opts['name'] and t.product_type === 'com.apple.product-type.framework' and [nil, platform].include? t.platform_name
					}.first
					next nil if remote_target == nil

					native_target.add_dependency remote_target

					[subproj.file_reference_proxies.select { |p| p.path == remote_target.product_reference.path }.first, f_opts]
				}.compact.each { |data|
					framework, f_opts = data
					framework_path = File.expand_path framework.path, File.dirname(f.project_path)
					framework_group.new_file framework_path

					native_target.frameworks_build_phase.add_file_reference framework

					if f_opts['copy']
						embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
						embed_phase.name = "Embed Framework #{framework.path}"
						embed_phase.symbol_dst_subfolder_spec = :frameworks
						native_target.build_phases.insert(native_target.build_phases.count, embed_phase)

						attributes = ['RemoveHeadersOnCopy']

						if f_opts['codeSignOnCopy']
							attributes << 'CodeSignOnCopy'
						end

						framework_build_file = embed_phase.add_file_reference framework
						framework_build_file.settings = { 'ATTRIBUTES' => attributes }
					end
				}
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

		private
		def self.write_xcodeproj(spec, filename)
			spec_xcodeproj_type_map = {}
			spec_xcodeproj_type_map['debug'] = :debug
			spec_xcodeproj_type_map['release'] = :release
			spec_configuration_type_map = {}

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
		# @param native_target [Xcodeproj::PBXNativeTarget]
		# @param project [Xcodeproj::Project]
		# @param project_working_dir [String]
		def self.add_files_to_target(target, native_target, project, project_directory)
			all_source_files = []
			grouped_source_files = {}
			source_files_minus_dir = []

			target.source_dir.each { |source_dir|
				# For some reason our symlink-traversing glob duplicates the results, so we use .uniq to fix that
				new_files = Dir.glob("#{source_dir}/**{,/*/**}/*").select { |file|
					!(file.include? '.xcassets/') and
						!(file.include? '.bundle/') and
						!(file.end_with? 'Info.plist') and
						!(file.include? '.lproj')
				}.uniq.select { |f|
					source_files_minus_dir.count(f.sub(source_dir, '')) == 0
				}

				new_files_minus_dir = new_files.map { |f| f.sub(source_dir, '') }
				all_source_files.unshift(*new_files)
				grouped_source_files[source_dir] = new_files
				source_files_minus_dir = source_files_minus_dir.unshift(*new_files_minus_dir).uniq
			}

			grouped_source_files.each { |source_dir, all_files|
				files = all_files.select { |file|
					!(target.file_excludes.any? { |exclude|
						File.fnmatch(exclude, file)
					})
				}

				files = files.select { |file|
					if File.directory?(file) and !file.end_with? '.xcassets'
						next false
					end

					next !(file.include? '.framework/') && !(file.include? '.xcdatamodeld/')
				}

				rel_source_root = source_dir.sub(project_directory, '')
				if rel_source_root.start_with? '/'
					rel_source_root[0] = ''
				end

				source_group = project.new_group(File.basename(source_dir), rel_source_root, 'SOURCE_ROOT')

				files.map { |file|
					new_file = file.sub(source_dir, '')
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
					elsif file.end_with? '.entitlements'
						next
					else
						native_target.add_resources [native_file]
					end
				}
			}

			if target.res_dir.count > 0
				target.res_dir.select { |res_dir|
					lfiles = Dir.glob(File.join(res_dir, '*.lproj', '**', '*'))
					if lfiles.length > 0
						resource_group = project.groups.find { |group| group.display_name == "$lang:#{target.name}" }
						if resource_group == nil
							resource_group = project.new_group("$lang:#{target.name}", nil, '<group>')
							resource_group.source_tree = 'SOURCE_ROOT'
						end

						# Create a virtual path since lproj files go through a layer of indirection before hitting the filesystem
						lproj_variant_files = []
						lfiles.map { |lfile|
							new_lfile = lfile.sub(res_dir, '')
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
							variant_group = resource_group.new_variant_group(lproj_file, res_dir, '<group>')
							# Add all lproj files to the variant group

							Dir.glob(File.join(res_dir, '*.lproj', lproj_file)).each { |file|
								native_file = variant_group.new_file(file, '<group>')
								native_target.add_resources [native_file]
							}
						}
					end
				}
			end

			framework_files = all_source_files.select { |file|
				file.end_with? '.framework'
			}

			framework_group = project.frameworks_group.groups.find { |group| group.display_name == '$local' }
			if framework_group == nil
				framework_group = project.frameworks_group.new_group '$local', nil, '<group>'
			end
			# The 'Embed Frameworks' phase is missing by default from the Xcodeproj template, so we have to add it.
			embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
			embed_phase.name = 'Embed Frameworks'
			embed_phase.symbol_dst_subfolder_spec = :frameworks
			native_target.build_phases.insert(native_target.build_phases.count, embed_phase)

			framework_files.map { |framework|
				framework_group.new_file framework
			}.each { |framework|
				(embed_phase.add_file_reference framework).settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
				native_target.frameworks_build_phase.add_file_reference framework
			}

			target.run_scripts.each { |script|
				script_name = script.script_path
				script = File.read(File.join(project_directory, script.script_path))

				script_phase = native_target.new_shell_script_build_phase script_name
				script_phase.shell_script = script
			}


		end
	end
end