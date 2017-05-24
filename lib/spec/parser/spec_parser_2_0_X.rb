require 'semantic'
require_relative '../../utils/xcconfig_parser'
require_relative '../../utils/type_helpers'
require_relative './parser_20X/utils'

module StructCore
	class Specparser20X
		include TypeHelpers
		include Utils20X
		# @param version [Semantic::Version]
		def can_parse_version(version)
			version.major == 2
		end

		def parse(spec_version, spec_hash, filename)
			@spec_file_uses_pods = false
			@spec_version = spec_version

			project_base_dir = File.dirname filename

			valid_configuration_names, configurations = parse_configurations spec_hash
			return Specfile.new(spec_version, [], configurations, [], project_base_dir) unless spec_hash.key? 'targets'
			raise StandardError.new "Error: Invalid spec file. Key 'targets' should be a hash" unless spec_hash['targets'].is_a?(Hash)

			targets = parse_targets spec_hash, valid_configuration_names, project_base_dir
			variants = parse_variants spec_hash, valid_configuration_names, project_base_dir
			pre_generate_script, post_generate_script = parse_scripts spec_hash['scripts'] || {}, project_base_dir
			schemes = parse_schemes spec_hash['schemes']

			Specfile.new(spec_version, targets, configurations, variants, project_base_dir, @spec_file_uses_pods, pre_generate_script, post_generate_script, schemes)
		end

		def parse_configurations(spec_hash)
			valid_configuration_names = []
			configurations = spec_hash['configurations'].map { |name, config|
				config ||= {}

				unless config['source'].nil?
					valid_configuration_names << name
					next Specfile::Configuration.new(name, [], {}, config['type'], config['source'])
				end

				valid_configuration_names << name
				config = Specfile::Configuration.new(name, [], config['overrides'] || {}, config['type'])

				if config.type.nil?
					puts Paint["Warning: Configuration with name '#{name}' was skipped as its type did not match one of: debug, release"]
					next nil
				end

				config.profiles = %w(general:release ios:release)
				config.profiles = %w(general:debug ios:debug) if config.type == 'debug'

				config
			}.compact
			raise StandardError.new 'Error: Invalid spec file. Project should have at least one configuration' unless configurations.count > 0

			[valid_configuration_names, configurations]
		end

		def parse_targets(spec_hash, valid_configuration_names, project_base_dir)
			(spec_hash['targets'] || {}).map { |target_name, target_opts|
				next nil if target_opts.nil?
				parse_target_pods target_opts
				parse_target_data(target_name, target_opts, project_base_dir, valid_configuration_names)
			}.compact
		end

		def parse_variants(spec_hash, valid_configuration_names, project_base_dir)
			variants = (spec_hash['variants'] || {}).map { |variant_name, variant_targets|
				parse_variant_data(variant_name, variant_targets, project_base_dir, valid_configuration_names)
			}.compact

			if variants.select { |variant| variant.name == '$base' }.count.zero?
				variants.push StructCore::Specfile::Variant.new('$base', [], false)
			end

			variants
		end

		def parse_variant_data(variant_name, variant_targets, project_base_dir, valid_configuration_names)
			return nil if (variant_name || '').empty? && variant_targets.nil?

			abstract = false
			targets = []

			(variant_targets || {}).each { |key, value|
				if key == 'abstract'
					abstract = true
				else
					parse_variant_target_pods value
					variant = parse_variant_target_data(key, value, project_base_dir, valid_configuration_names)
					targets.unshift(variant) unless variant.nil?
				end
			}

			StructCore::Specfile::Variant.new(variant_name, targets, abstract)
		end

		def parse_variant_target_type(target_opts)
			type = nil
			raw_type = nil
			# Parse target type
			if target_opts.key? 'type'
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
			end

			[raw_type, type]
		end

		def parse_variant_target_profiles(target_opts, raw_type, target_name)
			return [] unless target_opts['platform'].is_a?(String)

			raw_platform = target_opts['platform']
			unless %w(ios mac watch tv).include? raw_platform
				puts Paint["Warning: Variant for target #{target_name} specifies unrecognised platform '#{raw_platform}'. Ignoring...", :yellow]
				return []
			end

			[raw_type, "platform:#{raw_platform}"].compact
		end

		def parse_platform_variant_target_configuration_list(platform, configurations, valid_config_names, base_overrides, profiles)
			parse_variant_target_configuration_list(configurations, valid_config_names, base_overrides, profiles[platform]).map { |config|
				Specfile::Target::PlatformScopedConfiguration.new platform, config
			}
		end

		def parse_variant_target_configuration_list(configurations, valid_config_names, base_overrides, profiles)
			configurations.select { |n, _| n != '$base' }.map { |config_name, config|
				next nil unless valid_config_names.include? config_name

				if %w(ios mac tv watch).include?(config_name) && @spec_version.minor >= 2
					next parse_platform_variant_target_configuration_list config_name, config, valid_config_names, base_overrides, profiles
				end

				next Specfile::Target::Configuration.new(config_name, base_overrides, profiles, config) if config.is_a?(String)
				next Specfile::Target::Configuration.new(config_name, config.merge(base_overrides), profiles)
			}.compact
		end

		def parse_variant_target_configurations(target_opts, valid_config_names, profiles)
			# Parse target configurations
			configurations = nil
			if target_opts.key? 'configurations'
				base_overrides = target_opts['configurations']['$base'] || {}
				configurations = parse_variant_target_configuration_list target_opts['configurations'], valid_config_names, base_overrides, profiles
			elsif target_opts.key?('configuration') && target_opts['configuration'].is_a?(String)
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, {}, profiles, target_opts['configuration'])
				}
			elsif target_opts.key?('configuration') && target_opts['configuration'].is_a?(Hash)
				if %w(ios mac tv watch).any? { |s| target_opts['configuration'].key? s } && @spec_version.minor >= 2
					configurations = []
					target_opts['configuration'].each { |platform, overrides|
						configurations << valid_config_names.map { |name|
							Specfile::Target::Configuration.new(name, overrides, profiles[platform])
						}.map { |config|
							Specfile::Target::PlatformScopedConfiguration.new platform, config
						}

						configurations = nil if configurations.empty?
					}.flatten
				else
					configurations = valid_config_names.map { |name|
						Specfile::Target::Configuration.new(name, target_opts['configuration'], profiles)
					}
				end
			end

			configurations
		end

		def parse_variant_target_sources(target_opts, project_base_dir)
			# Parse target sources
			target_sources_dir = nil

			if target_opts.key? 'sources'
				target_sources_dir = target_opts['sources'].map { |src| File.join(project_base_dir, src) } if target_opts['sources'].is_a?(Array)
				target_sources_dir = [File.join(project_base_dir, target_opts['sources'])] if target_sources_dir.nil?

				target_sources_dir = target_sources_dir.select { |dir| Dir.exist? dir }
				target_sources_dir = nil unless target_sources_dir.count > 0
			end

			target_sources_dir
		end

		def parse_variant_target_resource_list(raw_res, project_base_dir)
			if raw_res.is_a?(Hash)
				raw_res.map { |platform, res|
					[].unshift(*parse_variant_target_resource_list(res, project_base_dir)).flatten.map { |r|
						StructCore::Specfile::Target::PlatformScopedResource.new platform, r
					}
				}.flatten
			elsif raw_res.is_a?(Array)
				raw_res.map { |r| File.join(project_base_dir, r) }
			else
				File.join(project_base_dir, raw_res)
			end
		end

		def parse_variant_target_resources(target_opts, project_base_dir)
			# Parse target resources
			return nil unless target_opts.key? 'i18n-resources'
			raw_res = target_opts['i18n-resources']

			parse_variant_target_resource_list raw_res, project_base_dir
		end

		def parse_variant_target_file_excludes(target_opts, target_name)
			# Parse excludes
			if target_opts.key?('excludes') && target_opts['excludes'].is_a?(Hash)
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

		def parse_variant_target_source_options(target_opts, target_name)
			return [] unless target_opts.key? 'source_options'
			unless target_opts['source_options'].is_a?(Hash)
				puts Paint["Warning: Target #{target_name}'s source options was not a Hash. Ignoring source options...", :yellow]
				return []
			end
			target_opts['source_options'].map { |name, settings|
				StructCore::Specfile::Target::FileOption.new(name, settings)
			}
		end

		def parse_variant_target_reference_list(references, target_name, project_base_dir)
			references.map { |raw_reference|
				next parse_raw_reference references unless raw_reference.is_a? Hash
				if raw_reference.key?('location')
					path = raw_reference['location']

					unless File.exist? File.join(project_base_dir, path)
						puts Paint["Warning: Reference #{path} could not be found. Ignoring...", :yellow]
						next nil
					end

					next Specfile::Target::FrameworkReference.new(path, raw_reference) unless raw_reference['frameworks'].nil?
					next Specfile::Target::LocalFrameworkReference.new(path, raw_reference) if path.end_with? '.framework'
					next Specfile::Target::LocalLibraryReference.new(path, raw_reference)

				elsif raw_reference.key?('target') && @spec_version.minor >= 2
					next Specfile::Target::TargetReference.new(raw_reference['target'], raw_reference)
				else
					puts Paint["Warning: Invalid reference found for target #{target_name}. Ignoring...", :yellow]
					next nil
				end
			}.compact
		end

		def parse_variant_target_references(target_opts, target_name, project_base_dir)
			return [] unless target_opts.key? 'references'
			raw_references = target_opts['references']

			if raw_references.is_a?(Hash) && @spec_version.minor >= 2
				return raw_references.map { |platform, references|
					parse_variant_target_reference_list(references, target_name, project_base_dir).map { |ref|
						Specfile::Target::PlatformScopedReference.new platform, ref
					}
				}.flatten
			end

			unless raw_references.is_a?(Array)
				puts Paint["Warning: Key 'references' for target #{target_name} is not an array. Ignoring...", :yellow]
				return []
			end

			parse_variant_target_reference_list raw_references, target_name, project_base_dir
		end

		def parse_raw_reference(raw_reference)
			# De-symbolise :sdkroot:-prefixed entries
			ref = raw_reference.to_s
			return Specfile::Target::TargetReference.new(raw_reference) unless ref.start_with? 'sdkroot:'
			return Specfile::Target::SystemFrameworkReference.new(raw_reference.sub('sdkroot:', '').sub('.framework', '')) if ref.end_with? '.framework'
			Specfile::Target::SystemLibraryReference.new(raw_reference.sub('sdkroot:', ''))
		end

		def parse_run_scripts_list(scripts, project_base_dir)
			scripts.map { |s|
				if s.is_a? String
					next nil if s.start_with? '/' # Script file should be relative to project
					next nil unless File.exist? File.join(project_base_dir, s)
					Specfile::Target::RunScript.new s
				elsif s.is_a?(Hash) && @spec_version.minor >= 2
					next nil unless s.key?('script')
					script = s['script']
					next nil if script.start_with? '/' # Script file should be relative to project
					next nil unless File.exist? File.join(project_base_dir, script)

					inputs = typed_default s['inputs'], Array, []
					outputs = typed_default s['outputs'], Array, []
					shell = typed_default s['shell'], String, nil

					Specfile::Target::RunScript.new script, inputs, outputs, shell
				else
					puts Paint['Warning: Invalid script found for target. Ignoring...', :yellow]
				end
			}.compact
		end

		def parse_variant_target_scripts(target_opts, project_base_dir)
			# Parse target run scripts
			return { prebuild_run_scripts: [], postbuild_run_scripts: [] } unless target_opts.key?('scripts')

			if target_opts['scripts'].is_a?(Array)
				{ prebuild_run_scripts: [], postbuild_run_scripts: parse_run_scripts_list(target_opts['scripts'], project_base_dir) }
			elsif target_opts['scripts'].is_a?(Hash)
				prebuild_run_scripts = []
				if target_opts['scripts']['prebuild'].is_a?(Array)
					prebuild_run_scripts = parse_run_scripts_list target_opts['scripts']['prebuild'], project_base_dir
				end

				postbuild_run_scripts = []
				if target_opts['scripts']['postbuild'].is_a?(Array)
					postbuild_run_scripts = parse_run_scripts_list target_opts['scripts']['postbuild'], project_base_dir
				end

				{ prebuild_run_scripts: prebuild_run_scripts, postbuild_run_scripts: postbuild_run_scripts }
			end
		end

		def parse_variant_target_data(target_name, target_opts, project_base_dir, valid_config_names)
			return nil if target_opts.nil? || !target_opts.is_a?(Hash)
			raw_type, type = parse_variant_target_type target_opts
			profiles = parse_variant_target_profiles target_opts, raw_type, target_name
			configurations = parse_variant_target_configurations target_opts, valid_config_names, profiles
			target_sources_dir = parse_variant_target_sources target_opts, project_base_dir
			target_resources_dir = parse_variant_target_resources target_opts, project_base_dir
			file_excludes = parse_variant_target_file_excludes target_opts, target_name
			options = parse_variant_target_source_options target_opts, target_name
			references = parse_variant_target_references target_opts, target_name, project_base_dir
			run_scripts = parse_variant_target_scripts target_opts, project_base_dir

			Specfile::Target.new(
				target_name, type, target_sources_dir, configurations, references, options, target_resources_dir,
				file_excludes, run_scripts[:postbuild_run_scripts], run_scripts[:prebuild_run_scripts]
			)
		end

		def parse_variant_target_pods(target_opts)
			return if @spec_file_uses_pods
			return if target_opts.nil? || !target_opts.is_a?(Hash)
			return unless [false, true].include? target_opts['includes_cocoapods']
			@spec_file_uses_pods = target_opts['includes_cocoapods']
		end

		def parse_target_type(target_opts)
			# Parse target type
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

		def parse_target_profile(platform, target_name, raw_type)
			unless platform.is_a?(String)
				puts Paint["Warning: Target #{target_name} does not specify a platform. Ignoring target."]
				return nil
			end

			raw_platform = platform
			unless %w(ios mac watch tv).include? raw_platform
				puts Paint["Warning: Target #{target_name} specifies unrecognised platform '#{raw_platform}'. Ignoring target...", :yellow]
				return nil
			end

			[raw_type, "platform:#{raw_platform}"]
		end

		def parse_target_profiles(target_opts, target_name, raw_type)
			if target_opts['platform'].is_a?(Array) && @spec_version.minor >= 2
				return target_opts['platform'].map { |platform|
					profiles = parse_target_profile platform, target_name, raw_type
					[platform, profiles]
				}.to_h
			end

			parse_target_profile target_opts['platform'], target_name, raw_type
		end

		def parse_platform_target_configuration_list(platform, configurations, valid_config_names, base_overrides, target_name, profiles)
			parse_target_configuration_list(configurations, valid_config_names, base_overrides, target_name, profiles[platform]).map { |config|
				Specfile::Target::PlatformScopedConfiguration.new platform, config
			}
		end

		def parse_target_configuration_list(configurations, valid_config_names, base_overrides, target_name, profiles)
			configurations.select { |n, _| n != '$base' }.map do |config_name, config|
				if %w(ios mac tv watch).include?(config_name) && @spec_version.minor >= 2
					next parse_platform_target_configuration_list config_name, config, valid_config_names, base_overrides, target_name, profiles
				end

				unless valid_config_names.include? config_name
					puts Paint["Warning: Config name #{config_name} for target #{target_name} was not defined in this spec. Ignoring target...", :yellow]
					return nil
				end

				next Specfile::Target::Configuration.new(config_name, base_overrides, profiles, config) if config.is_a?(String)
				next Specfile::Target::Configuration.new(config_name, config.merge(base_overrides), profiles)
			end
		end

		def parse_target_configurations(target_opts, target_name, profiles, valid_config_names)
			# Parse target configurations
			if target_opts.key?('configurations') && target_opts['configurations'].is_a?(Hash)
				base_overrides = target_opts['configurations']['$base'] || {}

				configurations = parse_target_configuration_list(target_opts['configurations'], valid_config_names, base_overrides, target_name, profiles).flatten
			elsif target_opts.key?('configuration') && target_opts['configuration'].is_a?(String)
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, {}, profiles, target_opts['configuration'])
				}
			elsif target_opts.key?('configuration') && target_opts['configuration'].is_a?(Hash)
				if %w(ios mac tv watch).any? { |s| target_opts['configuration'].key? s } && @spec_version.minor >= 2
					configurations = []
					target_opts['configuration'].each { |platform, overrides|
						configurations << valid_config_names.map { |name|
							Specfile::Target::Configuration.new(name, overrides, profiles[platform])
						}.map { |config|
							Specfile::Target::PlatformScopedConfiguration.new platform, config
						}
					}
					configurations.flatten!
				else
					configurations = valid_config_names.map { |name|
						Specfile::Target::Configuration.new(name, target_opts['configuration'], profiles)
					}
				end
			else
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, {}, profiles)
				}
			end

			configurations
		end

		def parse_target_source_list(sources, project_base_dir)
			if sources.is_a?(Hash)
				sources.map { |platform, srcs|
					[].unshift(*parse_target_source_list(srcs, project_base_dir)).flatten.map { |s|
						StructCore::Specfile::Target::PlatformScopedSource.new platform, s
					}
				}.flatten
			elsif sources.is_a?(Array)
				sources.map { |src| File.join(project_base_dir, src) }
			else
				[File.join(project_base_dir, sources)]
			end
		end

		def parse_target_sources(target_opts, target_name, project_base_dir)
			# Parse target sources
			unless target_opts.key? 'sources'
				puts Paint["Warning: Target #{target_name} contained no valid sources directories. Ignoring target...", :yellow]
				return nil
			end

			target_sources_dir = nil

			if target_opts.key? 'sources'
				target_sources_dir = parse_target_source_list target_opts['sources'], project_base_dir
				target_sources_dir = nil unless target_sources_dir.count > 0
			end

			target_sources_dir
		end

		def parse_target_resource_list(raw_res, project_base_dir)
			if raw_res.is_a?(Hash)
				raw_res.map { |platform, res|
					[].unshift(*parse_target_resource_list(res, project_base_dir)).flatten.map { |r|
						StructCore::Specfile::Target::PlatformScopedResource.new platform, r
					}
				}.flatten
			elsif raw_res.is_a?(Array)
				raw_res.map { |r| File.join(project_base_dir, r) }
			else
				File.join(project_base_dir, raw_res)
			end
		end

		def parse_target_resources(target_opts, project_base_dir, target_sources_dir)
			# Parse target resources
			return target_sources_dir unless target_opts.key? 'i18n-resources'
			raw_res = target_opts['i18n-resources']

			parse_target_resource_list(raw_res, project_base_dir) || target_sources_dir
		end

		def parse_target_excludes(target_opts, target_name)
			# Parse excludes
			if target_opts.key?('excludes') && target_opts['excludes'].is_a?(Hash)
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

		def parse_target_source_options(target_opts, target_name)
			return [] unless target_opts.key? 'source_options'
			unless target_opts['source_options'].is_a?(Hash)
				puts Paint["Warning: Target #{target_name}'s source options was not a Hash. Ignoring source options...", :yellow]
				return []
			end
			target_opts['source_options'].map { |name, settings|
				StructCore::Specfile::Target::FileOption.new(name, settings)
			}
		end

		def parse_target_reference_list(references, target_name, project_base_dir)
			references.map { |raw_reference|
				next parse_raw_reference raw_reference unless raw_reference.is_a? Hash
				if raw_reference.key?('location')
					path = raw_reference['location']

					unless !path.nil? && File.exist?(File.join(project_base_dir, path))
						puts Paint["Warning: Reference #{path} could not be found. Ignoring...", :yellow]
						next nil
					end

					if raw_reference['frameworks'].nil?
						next Specfile::Target::LocalFrameworkReference.new(path, raw_reference) if path.end_with? '.framework'
						next Specfile::Target::LocalLibraryReference.new(path, raw_reference)
					end

					next Specfile::Target::FrameworkReference.new(path, raw_reference)
				elsif raw_reference.key?('target') && @spec_version.minor >= 2
					next Specfile::Target::TargetReference.new(raw_reference['target'], raw_reference)
				else
					puts Paint["Warning: Invalid reference found for target #{target_name}. Ignoring...", :yellow]
					next nil
				end
			}.compact
		end

		def parse_target_references(target_opts, target_name, project_base_dir)
			return [] unless target_opts.key? 'references'
			raw_references = target_opts['references']

			if raw_references.is_a?(Hash) && @spec_version.minor >= 2
				return raw_references.map { |platform, references|
					parse_target_reference_list(references, target_name, project_base_dir).map { |ref|
						Specfile::Target::PlatformScopedReference.new platform, ref
					}
				}.flatten
			end

			unless raw_references.is_a?(Array)
				puts Paint["Warning: Key 'references' for target #{target_name} is not an array. Ignoring...", :yellow]
				return []
			end

			parse_target_reference_list raw_references, target_name, project_base_dir
		end

		def parse_target_scripts(target_opts, project_base_dir)
			# Parse target run scripts
			return { prebuild_run_scripts: [], postbuild_run_scripts: [] } unless target_opts.key?('scripts')

			if target_opts['scripts'].is_a?(Array)
				{ prebuild_run_scripts: [], postbuild_run_scripts: parse_run_scripts_list(target_opts['scripts'], project_base_dir) }
			elsif target_opts['scripts'].is_a?(Hash)
				prebuild_run_scripts = []
				if target_opts['scripts']['prebuild'].is_a?(Array)
					prebuild_run_scripts = parse_run_scripts_list target_opts['scripts']['prebuild'], project_base_dir
				end

				postbuild_run_scripts = []
				if target_opts['scripts']['postbuild'].is_a?(Array)
					postbuild_run_scripts = parse_run_scripts_list target_opts['scripts']['postbuild'], project_base_dir
				end

				{ prebuild_run_scripts: prebuild_run_scripts, postbuild_run_scripts: postbuild_run_scripts }
			end
		end

		# @return StructCore::Specfile::Target
		def parse_target_data(target_name, target_opts, project_base_dir, valid_config_names)
			unless target_opts.key? 'type'
				puts Paint["Warning: Target #{target_name} has no target type. Ignoring target...", :yellow]
				return nil
			end

			raw_type, type = parse_target_type target_opts
			profiles = parse_target_profiles target_opts, target_name, raw_type
			configurations = parse_target_configurations target_opts, target_name, profiles, valid_config_names

			unless configurations_valid? configurations, valid_config_names
				puts Paint["Warning: Missing configurations for target #{target_name}. Ignoring target...", :yellow]
				return nil
			end

			target_sources_dir = parse_target_sources target_opts, target_name, project_base_dir
			if target_sources_dir.nil?
				puts Paint["Warning: Target #{target_name} contained no valid sources directories. Ignoring target...", :yellow]
				return nil
			end

			target_resources_dir = parse_target_resources target_opts, project_base_dir, target_sources_dir
			file_excludes = parse_target_excludes target_opts, target_name
			references = parse_target_references target_opts, target_name, project_base_dir
			options = parse_target_source_options target_opts, target_name
			run_scripts = parse_target_scripts target_opts, project_base_dir

			Specfile::Target.new(
				target_name, type, target_sources_dir, configurations, references, options, target_resources_dir,
				file_excludes, run_scripts[:postbuild_run_scripts], run_scripts[:prebuild_run_scripts]
			)
		end

		def parse_target_pods(target_opts)
			return if @spec_file_uses_pods
			return if target_opts.nil? || !target_opts.is_a?(Hash)
			return unless [false, true].include? target_opts['includes_cocoapods']
			@spec_file_uses_pods = target_opts['includes_cocoapods']
		end

		def parse_scripts(scripts_opts, project_base_dir)
			return unless scripts_opts.is_a?(Hash)

			pre_generate = nil
			post_generate = nil

			if scripts_opts.key?('pre-generate') && File.exist?(File.join(project_base_dir, scripts_opts['pre-generate']))
				pre_generate = StructCore::Specfile::HookScript.new(File.join(project_base_dir, scripts_opts['pre-generate']))
			end

			if scripts_opts.key?('post-generate') && File.exist?(File.join(project_base_dir, scripts_opts['post-generate']))
				post_generate = StructCore::Specfile::HookScript.new(File.join(project_base_dir, scripts_opts['post-generate']))
			end

			[pre_generate, post_generate]
		end

		def parse_schemes(scheme_opts)
			return [] unless scheme_opts.is_a?(Hash)

			scheme_opts.map { |name, opts|
				build_action = parse_scheme_build_action opts['build'], name
				test_action = parse_scheme_test_action opts['test'], name
				launch_action = parse_scheme_launch_action opts['launch'], name
				archive_action = parse_scheme_archive_action opts['archive'], name
				profile_action = parse_scheme_profile_action opts['profile'], name
				analyze_action = parse_scheme_analyze_action opts['analyze']

				StructCore::Specfile::Scheme.new name, build_action, test_action, launch_action, archive_action, profile_action, analyze_action
			}
		end

		def parse_scheme_build_action(opts, scheme_name)
			return nil if opts.nil?
			parallel = false
			parallel = opts['parallel'] if opts.key? 'parallel'

			build_implicit = false
			build_implicit = opts['build_implicit'] if opts.key? 'build_implicit'

			targets = []
			unless opts['targets'].is_a? Hash
				puts Paint["Warning: Found invalid targets entry for scheme #{scheme_name}'s build action. Ignoring.'"]
				return StructCore::Specfile::Scheme::BuildAction.new targets, parallel, build_implicit
			end

			targets = opts['targets'].map { |name, target_opts|
				archiving_enabled = false
				archiving_enabled = target_opts['archiving_enabled'] if target_opts.key? 'archiving_enabled'

				running_enabled = false
				running_enabled = target_opts['running_enabled'] if target_opts.key? 'running_enabled'

				profiling_enabled = false
				profiling_enabled = target_opts['profiling_enabled'] if target_opts.key? 'profiling_enabled'

				testing_enabled = false
				testing_enabled = target_opts['testing_enabled'] if target_opts.key? 'testing_enabled'

				analyzing_enabled = false
				analyzing_enabled = target_opts['analyzing_enabled'] if target_opts.key? 'analyzing_enabled'

				StructCore::Specfile::Scheme::BuildAction::BuildActionTarget.new name, archiving_enabled, running_enabled, profiling_enabled, testing_enabled, analyzing_enabled
			}

			StructCore::Specfile::Scheme::BuildAction.new targets, parallel, build_implicit
		end

		def parse_scheme_test_action(opts, scheme_name)
			return nil if opts.nil?

			unless opts['build_configuration'].is_a?(String) && !opts['build_configuration'].empty?
				puts Paint["Warning: Missing build_configuration entry for scheme #{scheme_name}'s test action. Ignoring action.'"]
				return nil
			end

			inherit_launch_arguments = false
			inherit_launch_arguments = opts['inherit_launch_arguments'] if opts.key? 'inherit_launch_arguments'

			code_coverage_enabled = false
			code_coverage_enabled = opts['code_coverage_enabled'] if opts.key? 'code_coverage_enabled'

			environment = {}
			environment = opts['environment'] if opts.key?('environment') && opts['environment'].is_a?(Hash)

			targets = []
			unless opts['targets'].is_a? Array
				puts Paint["Warning: Found invalid targets entry for scheme #{scheme_name}'s test action. Ignoring.'"]
				return StructCore::Specfile::Scheme::TestAction.new opts['build_configuration'], targets, inherit_launch_arguments, code_coverage_enabled, environment
			end

			targets = opts['targets']

			StructCore::Specfile::Scheme::TestAction.new opts['build_configuration'], targets, inherit_launch_arguments, code_coverage_enabled, environment
		end

		def parse_scheme_archive_action(opts, scheme_name)
			return nil if opts.nil?

			unless opts['name'].is_a?(String) && !opts['name'].empty?
				puts Paint["Warning: Missing name entry for scheme #{scheme_name}'s archive action. Ignoring action.'"]
				return nil
			end

			reveal = false
			reveal = opts['reveal'] if opts.key? 'reveal'

			build_configuration = nil
			if @spec_version.major == 2 && @spec_version.minor >= 1
				build_configuration = opts['build_configuration'] if opts.key? 'build_configuration'
			end

			StructCore::Specfile::Scheme::ArchiveAction.new opts['name'], reveal, build_configuration
		end

		def parse_scheme_launch_action(opts, scheme_name)
			return nil if opts.nil?

			unless opts['target'].is_a?(String) && !opts['target'].empty?
				puts Paint["Warning: Missing target entry for scheme #{scheme_name}'s launch action. Ignoring action.'"]
				return nil
			end

			simulate_location = false
			simulate_location = opts['simulate_location'] if opts.key? 'simulate_location'

			arguments = ''
			arguments = opts['arguments'] if opts.key?('arguments') && opts['arguments'].is_a?(String)

			environment = {}
			environment = opts['environment'] if opts.key?('environment') && opts['environment'].is_a?(Hash)

			build_configuration = nil
			if @spec_version.major == 2 && @spec_version.minor >= 1
				build_configuration = opts['build_configuration'] if opts.key? 'build_configuration'
			end

			StructCore::Specfile::Scheme::LaunchAction.new opts['target'], simulate_location, arguments, environment, build_configuration
		end

		def parse_scheme_profile_action(opts, scheme_name)
			return nil if opts.nil?

			unless opts['target'].is_a?(String) && !opts['target'].empty?
				puts Paint["Warning: Missing target entry for scheme #{scheme_name}'s profile action. Ignoring action.'"]
				return nil
			end

			inherit_environment = false
			inherit_environment = opts['inherit_environment'] if opts.key? 'inherit_environment'

			build_configuration = nil
			if @spec_version.major == 2 && @spec_version.minor >= 1
				build_configuration = opts['build_configuration'] if opts.key? 'build_configuration'
			end

			StructCore::Specfile::Scheme::ProfileAction.new opts['target'], inherit_environment, build_configuration
		end

		def parse_scheme_analyze_action(opts)
			return nil if opts.nil? || @spec_version.minor < 2

			build_configuration = nil
			build_configuration = opts['build_configuration'] if opts.key? 'build_configuration'
			StructCore::Specfile::Scheme::AnalyzeAction.new build_configuration
		end

		private :parse_configurations
		private :parse_targets
		private :parse_variants
		private :parse_variant_data
		private :parse_variant_target_type
		private :parse_variant_target_profiles
		private :parse_variant_target_configurations
		private :parse_variant_target_sources
		private :parse_variant_target_resources
		private :parse_variant_target_file_excludes
		private :parse_variant_target_source_options
		private :parse_variant_target_references
		private :parse_run_scripts_list
		private :parse_variant_target_scripts
		private :parse_variant_target_data
		private :parse_variant_target_pods
		private :parse_target_type
		private :parse_target_profiles
		private :parse_target_configurations
		private :parse_target_sources
		private :parse_target_resources
		private :parse_target_excludes
		private :parse_target_source_options
		private :parse_target_references
		private :parse_target_scripts
		private :parse_target_data
		private :parse_target_pods
		private :parse_scripts
		private :parse_schemes
		private :parse_scheme_build_action
		private :parse_scheme_archive_action
		private :parse_scheme_launch_action
		private :parse_scheme_profile_action
	end
end