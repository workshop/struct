require 'paint'
require 'xcodeproj'
require 'semantic'
require_relative '../spec/spec_file'

module Xcodegen
	class Migrator
		CONFIG_PROFILE_PATH = File.join(__dir__, '..', '..', 'res', 'config_profiles')
		TARGET_CONFIG_PROFILE_PATH = File.join(__dir__, '..', '..', 'res', 'target_config_profiles')
		DEBUG_SETTINGS_MERGED = ['general:debug', 'ios:debug'].map { |profile_name|
			[profile_name, File.join(CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
		}.map { |data|
			profile_name, profile_file_name = data
			unless File.exist? profile_file_name
				puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
				next nil
			end

			next YAML.load_file(profile_file_name)
		}.inject({}) { |settings, next_settings|
			settings.merge (next_settings || {})
		}
		RELEASE_SETTINGS_MERGED = ['general:release', 'ios:release'].map { |profile_name|
			[profile_name, File.join(CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
		}.map { |data|
			profile_name, profile_file_name = data
			unless File.exist? profile_file_name
				puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
				next nil
			end

			next YAML.load_file(profile_file_name)
		}.inject({}) { |settings, next_settings|
			settings.merge (next_settings || {})
		}

		def self.migrate(xcodeproj_file, directory)
			xcodeproj_path = (Pathname.new(xcodeproj_file)).absolute? ? xcodeproj_file : File.join(Dir.pwd, xcodeproj_file)

			unless File.exist? xcodeproj_path
				raise StandardError.new 'Invalid xcode project'
			end

			project = Xcodeproj::Project.open(xcodeproj_path)
			project_dir = File.dirname(xcodeproj_path)

			spec_version = Semantic::Version.new('1.0.0')
			configurations = migrate_build_configurations project

			targets = project.targets.map { |target|
				name = target.name
				type = target.product_type.sub 'com.apple.product-type.', ':'
				if target.sdk.include? 'iphoneos'
					profiles = ['platform:ios', type.sub(':', '')]
				elsif target.sdk.include? 'macosx'
					profiles = ['platform:mac', type.sub(':', '')]
				elsif target.sdk.include? 'appletvos'
					profiles = ['platform:tvos', type.sub(':', '')]
				elsif target.sdk.include? 'watchos'
					profiles = ['platform:watchos', type.sub(':', '')]
				else
					raise StandardError.new "Unrecognised SDK #{target.sdk} for target: #{name}"
				end

				target_configuration_overrides = target.build_configurations.map { |config|
					config_name = config.name
					config_name = name.downcase if ['Debug', 'Release'].include? name

					[config_name, extract_target_config_overrides(profiles, config.build_settings)]
				}.to_h

				target_references = target.frameworks_build_phase.files.map { |f|
					if f.file_ref.source_tree == 'SDKROOT'
						if f.file_ref.path.start_with? 'System/Library/Frameworks'
							Xcodegen::Specfile::Target::SystemFrameworkReference.new(f.file_ref.path.sub('System/Library/Frameworks/', '').sub('.framework', ''))
						elsif f.file_ref.path.start_with? 'usr/lib'
							Xcodegen::Specfile::Target::SystemLibraryReference.new(f.file_ref.path.sub('usr/lib/', ''))
						else
							next nil
						end
					else
						# TODO: Support migrating local frameworks
						next nil
					end
				}.compact

				Xcodegen::Specfile::Target.new(
					name,
					type,
					"src-#{name.downcase.sub(' ', '_')}",
					target.build_configurations.map { |config|
						Xcodegen::Specfile::Target::Configuration.new(
							config.name, target_configuration_overrides[config.name], profiles
						)
					},
					target_references,
					[],
					nil,
					[]
				)
			}

			targets_files = project.targets.map { |target|
				target_files = target.source_build_phase.files.map { |file| file.file_ref.real_path }
				target_files.unshift *(target.resources_build_phase.files.map { |file| file.file_ref.real_path }.compact)
				target_files = target_files.map { |f| f.to_s }
				target_files = target_files.select { |f| !File.directory?(f) || f.end_with?('xcassets') }
				target_glob_files = target_files.select { |f|
					File.directory? f
				}.flatten
				target_files = target_files.select { |f|
					!target_glob_files.include? f
				}
				target_files.unshift *(target_glob_files.map { |f|
					Dir[File.join f, '**', '*']
				}.flatten.select { |f|
					!File.directory? f
				})

				target_res_files = target.resources_build_phase.files.select { |f|
					f.file_ref.name != nil && (
						f.file_ref.name.end_with?('.storyboard') ||
						f.file_ref.name.end_with?('.strings') ||
						f.file_ref.name.end_with?('.stringsdict')
					)
				}.map { |f|
					f.file_ref.name
				}

				target_files.unshift *(Dir[File.join project_dir, '**', '*.lproj', '**', '*'].select { |f|
					!File.directory?(f) && target_res_files.include?(File.basename(f))
				})

				[target.name, target_files]
			}

			spec_file = Xcodegen::Specfile.new(spec_version, targets, configurations, directory)
			spec_file.write File.join(directory, 'project.yml')

			targets_files.each { |name, files|
				destination_dir = File.join directory, "src-#{name.downcase.sub(' ', '_')}"
				FileUtils.mkdir_p destination_dir

				files.each { |f|
					FileUtils.mkdir_p File.dirname(f.sub(project_dir, destination_dir))
					FileUtils.cp_r f, f.sub(project_dir, destination_dir)
				}
			}
		end

		private
		def self.migrate_build_configurations(project)
			project.build_configurations.map { |config|
				if config.type == :debug
					overrides = config.build_settings.reject { |k, _| DEBUG_SETTINGS_MERGED.include? k }
					next Xcodegen::Specfile::Configuration.new(config.name, ['general:debug', 'ios:debug'], overrides, 'debug')
				elsif config.type == :release
					overrides = config.build_settings.reject { |k, _| RELEASE_SETTINGS_MERGED.include? k }
					next Xcodegen::Specfile::Configuration.new(config.name, ['general:release', 'ios:release'], overrides, 'release')
				else
					raise StandardError.new "Unsupported build configuration type: #{config.type}"
				end
			}
		end

		def self.extract_target_config_overrides(profiles, build_settings)
			default_settings = profiles.map { |profile_name|
				[profile_name, File.join(TARGET_CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
			}.map { |data|
				profile_name, profile_file_name = data
				unless File.exist? profile_file_name
					puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
					next nil
				end

				next YAML.load_file(profile_file_name)
			}.inject({}) { |settings, next_settings|
				settings.merge (next_settings || {})
			}

			build_settings.reject { |k, _| default_settings.include? k }
		end
	end
end