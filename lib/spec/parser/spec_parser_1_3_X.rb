require 'semantic'
require_relative '../../utils/xcconfig_parser'

module StructCore
	class Specparser13X
		# @param version [Semantic::Version]
		def can_parse_version(version)
			version.major == 1 && version.minor == 3
		end

		def parse(spec_version, spec_hash, filename)
			@spec_file_uses_pods = false

			project_base_dir = File.dirname filename

			valid_configuration_names, configurations = parse_configurations spec_hash
			return Specfile.new(spec_version, [], configurations, [], project_base_dir) unless spec_hash.key? 'targets'
			raise StandardError.new "Error: Invalid spec file. Key 'targets' should be a hash" unless spec_hash['targets'].is_a?(Hash)

			targets = parse_targets spec_hash, valid_configuration_names, project_base_dir
			variants = parse_variants spec_hash, valid_configuration_names, project_base_dir

			Specfile.new(spec_version, targets, configurations, variants, project_base_dir, @spec_file_uses_pods)
		end

		def parse_configurations(spec_hash)
			valid_configuration_names = []
			configurations = spec_hash['configurations'].map { |name, config|
			
				unless config['source'].nil?
					valid_configuration_names << name
					next Specfile::Configuration.new(name, [], {}, config['type'], config['source'])
				end

				valid_configuration_names << name
				config = Specfile::Configuration.new(name, config['overrides'] || {}, config['type'])
				
				if config.type.nil?
					puts Paint["Warning: Configuration with name '#{name}' was skipped as its type did not match one of: debug, release"]
					next nil
				end

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
			# Parse target platform/type/profiles into a profiles list
			platform = target_opts['platform']
			[raw_type, "platform:#{platform}"].compact
		end

		def parse_variant_target_configurations(target_opts, valid_config_names, profiles)
			# Parse target configurations
			configurations = nil
			if target_opts.key? 'configurations'
				configurations = target_opts['configurations'].map { |config_name, config|
					next nil unless valid_config_names.include? config_name

					next Specfile::Target::Configuration.new(config_name, {}, profiles, config) if config.is_a?(String)
					next Specfile::Target::Configuration.new(config_name, config, profiles)
				}.compact
			elsif target_opts.key?('configuration') && target_opts['configuration'].is_a?(String)
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, {}, profiles, target_opts['configuration'])
				}
			elsif target_opts.key?('configuration')
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, target_opts['configuration'], profiles)
				}
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

		def parse_variant_target_resources(target_opts, project_base_dir)
			# Parse target resources
			target_resources_dir = nil
			target_resources_dir = File.join(project_base_dir, target_opts['i18n-resources']) if target_opts.key? 'i18n-resources'

			target_resources_dir
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

		def parse_variant_target_references(target_opts, target_name, project_base_dir)
			return [] unless target_opts.key? 'references'
			raw_references = target_opts['references']

			unless raw_references.is_a?(Array)
				puts Paint["Warning: Key 'references' for target #{target_name} is not an array. Ignoring...", :yellow]
				return []
			end

			raw_references.map { |raw_reference|
				if raw_reference.is_a?(Hash)
					path = raw_reference['location']

					unless File.exist? File.join(project_base_dir, path)
						puts Paint["Warning: Reference #{path} could not be found. Ignoring...", :yellow]
						next nil
					end

					if raw_reference['frameworks'].nil?
						next Specfile::Target::LocalFrameworkReference.new(path, raw_reference) if path.end_with? '.framework'
						next Specfile::Target::LocalLibraryReference.new(path, raw_reference)
					end

					next Specfile::Target::FrameworkReference.new(path, raw_reference)
				else
					# De-symbolise :sdkroot:-prefixed entries
					ref = raw_reference.to_s
					next Specfile::Target::TargetReference.new(raw_reference) unless ref.start_with? 'sdkroot:'
					next Specfile::Target::SystemFrameworkReference.new(raw_reference.sub('sdkroot:', '').sub('.framework', '')) if ref.end_with? '.framework'
					next Specfile::Target::SystemLibraryReference.new(raw_reference.sub('sdkroot:', ''))
				end
			}.compact
		end

		def parse_run_scripts_list(scripts, project_base_dir)
			scripts.map { |s|
				next nil if s.start_with? '/' # Script file should be relative to project
				next nil unless File.exist? File.join(project_base_dir, s)
				Specfile::Target::RunScript.new s
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
			references = parse_variant_target_references target_opts, target_name, project_base_dir
			run_scripts = parse_variant_target_scripts target_opts, project_base_dir

			Specfile::Target.new(
				target_name, type, target_sources_dir, configurations, references, [], target_resources_dir,
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

		def parse_target_profiles(target_opts, target_name, raw_type)
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
				# TODO: Add support for 'tvos', 'watchos'
				unless %w(ios mac).include? raw_platform
					puts Paint["Warning: Target #{target_name} specifies unrecognised platform '#{raw_platform}'. Ignoring target...", :yellow]
					return nil
				end

				profiles = [raw_type, "platform:#{raw_platform}"]
			end

			profiles
		end

		# rubocop:disable Style/ConditionalAssignment
		def parse_target_configurations(target_opts, target_name, profiles, valid_config_names)
			# Parse target configurations
			if target_opts.key?('configurations') && target_opts['configurations'].is_a?(Hash)
				configurations = target_opts['configurations'].map do |config_name, config|
					unless valid_config_names.include? config_name
						puts Paint["Warning: Config name #{config_name} for target #{target_name} was not defined in this spec. Ignoring target...", :yellow]
						return nil
					end

					next Specfile::Target::Configuration.new(config_name, {}, profiles, config) if config.is_a?(String)
					next Specfile::Target::Configuration.new(config_name, config, profiles)
				end
			elsif target_opts.key?('configuration') && target_opts['configuration'].is_a?(String)
				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, {}, profiles, target_opts['configuration'])
				}
			elsif target_opts.key?('configuration')
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
		# rubocop:enable Style/ConditionalAssignment

		def parse_target_sources(target_opts, target_name, project_base_dir)
			# Parse target sources
			unless target_opts.key? 'sources'
				puts Paint["Warning: Target #{target_name} contained no valid sources directories. Ignoring target...", :yellow]
				return nil
			end

			target_sources_dir = nil

			if target_opts.key? 'sources'
				target_sources_dir = target_opts['sources'].map { |src| File.join(project_base_dir, src) } if target_opts['sources'].is_a?(Array)
				target_sources_dir = [File.join(project_base_dir, target_opts['sources'])] if target_sources_dir.nil?
				target_sources_dir = target_sources_dir.select { |dir| Dir.exist? dir }
				target_sources_dir = nil unless target_sources_dir.count > 0
			end

			target_sources_dir
		end

		def parse_target_resources(target_opts, project_base_dir, target_sources_dir)
			# Parse target resources
			target_resources_dir = nil
			target_resources_dir = File.join(project_base_dir, target_opts['i18n-resources']) if target_opts.key? 'i18n-resources'
			target_resources_dir = target_sources_dir if target_resources_dir.nil?

			target_resources_dir
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

		def parse_target_references(target_opts, target_name, project_base_dir)
			return [] unless target_opts.key? 'references'
			raw_references = target_opts['references']

			unless raw_references.is_a?(Array)
				puts Paint["Warning: Key 'references' for target #{target_name} is not an array. Ignoring...", :yellow]
				return []
			end

			raw_references.map { |raw_reference|
				if raw_reference.is_a?(Hash)
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
				else
					# De-symbolise :sdkroot:-prefixed entries
					ref = raw_reference.to_s
					next Specfile::Target::TargetReference.new(raw_reference) unless ref.start_with? 'sdkroot:'
					next Specfile::Target::SystemFrameworkReference.new(raw_reference.sub('sdkroot:', '').sub('.framework', '')) if ref.end_with? '.framework'
					next Specfile::Target::SystemLibraryReference.new(raw_reference.sub('sdkroot:', ''))
				end
			}.compact
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

			unless configurations.count == valid_config_names.count
				puts Paint["Warning: Missing configurations for target #{target_name}. Expected #{valid_config_names.count}, found: #{configurations.count}. Ignoring target...", :yellow]
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
			run_scripts = parse_target_scripts target_opts, project_base_dir

			Specfile::Target.new(
				target_name, type, target_sources_dir, configurations, references, [], target_resources_dir,
				file_excludes, run_scripts[:postbuild_run_scripts], run_scripts[:prebuild_run_scripts]
			)
		end

		def parse_target_pods(target_opts)
			return if @spec_file_uses_pods
			return if target_opts.nil? || !target_opts.is_a?(Hash)
			return unless [false, true].include? target_opts['includes_cocoapods']
			@spec_file_uses_pods = target_opts['includes_cocoapods']
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
		private :parse_variant_target_references
		private :parse_variant_target_data
	end
end