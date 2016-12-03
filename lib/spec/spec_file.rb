require 'json'
require 'semantic'

module Xcodegen
	class Specfile
		class Configuration
			def initialize(name, profiles, overrides, type=nil)
				@name = name
				@profiles = profiles
				@overrides = overrides
				@type = type
			end

			def type
				if name == 'debug'
					'debug'
				elsif name == 'release'
					'release'
				else
					@type
				end
			end

			# @return [String]
			def name
				@name
			end

			# @return [Array<String>]
			def profiles
				@profiles
			end

			# @return [Hash]
			def overrides
				@overrides
			end
		end

		class Target
			class Configuration
				def initialize(name, settings, profiles=nil)
					@name = name
					@settings = settings
					@profiles = profiles || []
				end

				# @return [String]
				def name
					@name
				end

				# @return [Hash]
				def settings
					@settings
				end

				# @return [Array<String>]
				def profiles
					@profiles
				end
			end

			class TargetReference
				def initialize(target_name)
					@target_name = target_name
				end

				# @return [String]
				def target_name
					@target_name
				end
			end

			class FrameworkReference
				def initialize(project_path, settings)
					@project_path = project_path
					@settings = settings
				end

				# @return [String]
				def project_path
					@project_path
				end

				# @return [Hash]
				def settings
					@settings
				end
			end

			class FileOption
				def initialize(glob, options)
					@glob = glob
					@options = options
				end

				# @return [String]
				def glob
					@glob
				end

				# @return [Hash]
				def options
					@options
				end
			end

			class FrameworkOption
				def initialize(name, options)
					@name = name
					@options = options
				end

				# @return [String]
				def name
					@name
				end

				# @return [Hash]
				def options
					@options
				end
			end

			# @param target_name [String]
			# @param target_type [String]
			# @param source_dir [String]
			# @param configurations [Array<Xcodegen::Specfile::Target::Configuration>]
			# @param references [Array<Xcodegen::Specfile::Target::FrameworkReference>]
			# @param options [Array<Xcodegen::Specfile::Target::FileOption, Xcodegen::Specfile::Target::FrameworkOption>]
			# @param res_dir [String]
			def initialize(target_name, target_type, source_dir, configurations, references, options, res_dir)
				@name = target_name
				@type = target_type
				@source_dir = source_dir
				@configurations = configurations
				@references = references
				@options = options
				@res_dir = res_dir || source_dir
			end

			# @return [String]
			def name
				@name
			end

			# @return [Array<Xcodegen::Specfile::Target::Configuration>]
			def configurations
				@configurations
			end

			# @return [Array<Xcodegen::Specfile::Target::TargetReference, Array<Xcodegen::Specfile::Target::FrameworkReference>]
			def references
				@references
			end

			# @return [Array<Xcodegen::Specfile::Target::FileOption, Xcodegen::Specfile::Target::FrameworkOption>]
			def options
				@options
			end

			# @return [String]
			def type
				@type
			end

			# @return [String]
			def source_dir
				@source_dir
			end

			# @return [String]
			def res_dir
				@res_dir
			end

			def self.create(target_name, target_opts, project_base_dir, valid_config_names)
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
					unless target_opts['configurations'].is_a?(Array)
						puts Paint["Warning: Key 'configurations' for target #{target_name} is not an array. Ignoring target...", :yellow]
						return nil
					end
					configurations = target_opts['configurations'].map do |config_name, config|
						unless valid_config_names.include? config_name
							puts Paint["Warning: Config name #{config_name} for target #{target_name} was not defined in this spec. Ignoring target...", :yellow]
							return nil
						end
						Target::Configuration.new(config_name, config, profiles)
					end
				elsif target_opts.key? 'configuration'
					configurations = valid_config_names.map { |name|
						Target::Configuration.new(name, target_opts['configuration'], profiles)
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

				# Parse target ressources
				if target_opts.key? 'i18n-resources'
					target_resources_dir = File.join(project_base_dir, target_opts['i18n-resources'])
				else
					target_resources_dir = target_sources_dir
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

								next Target::FrameworkReference.new(project_path, raw_reference)
							else
								next Target::TargetReference.new(raw_reference)
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
									Target::FileOption.new(glob, fileOpts)
								}
							else
								puts Paint["Warning: Key 'files' for target #{target_name}'s options is not a hash. Ignoring...", :yellow]
							end
						end

						if target_opts['options'].key? 'frameworks'
							if target_opts['options']['frameworks'].is_a?(Hash)
								options.unshift *target_opts['options']['frameworks'].map { |name, frameworkOpts|
									Target::FrameworkOption.new(name, frameworkOpts)
								}
							else
								puts Paint["Warning: Key 'frameworks' for target #{target_name}'s options is not a hash. Ignoring...", :yellow]
							end
						end
					else
						puts Paint["Warning: Key 'options' for target #{target_name} is not a hash. Ignoring...", :yellow]
					end
				end

				return Target.new target_name, type, target_sources_dir, configurations, references, options, target_resources_dir
			end
		end

		# @param version [String]
		# @param targets [Array<Xcodegen::Specfile::Target>]
		# @param configurations [Array<Xcodegen::Specfile::Configuration>]
		def initialize(version, targets, configurations, base_dir)
			@version = version
			@targets = targets
			@configurations = configurations
			@base_dir = base_dir
		end

		def self.parse(path)
			filename = (Pathname.new(path)).absolute? ? path : File.join(Dir.pwd, path)
			raise StandardError.new "Error: Spec file #{filename} does not exist" unless File.exist? filename

			if filename.end_with? 'yml' or filename.end_with? 'yaml'
				spec_hash = YAML.load_file filename
			elsif filename.end_with? 'json'
				spec_hash = JSON.parse File.read(filename)
			else
				raise StandardError.new 'Error: Unable to determine file format of project file'
			end

			raise StandardError.new "Error: Invalid spec file. No 'version' key was present." unless spec_hash != nil and spec_hash.key? 'version'

			begin
				spec_version = Semantic::Version.new spec_hash['version']
			rescue StandardError => _
				raise StandardError.new 'Error: Invalid spec file. Project version is invalid.'
			end
			raise StandardError.new 'Error: Invalid spec file. Project version is newer than this version of xcodegen supports.' unless spec_version.major <=1 and spec_version.minor <= 0 and spec_version.patch <= 0

			raise StandardError.new "Error: Invalid spec file. No 'configurations' key was present." unless spec_hash.key? 'configurations'
			raise StandardError.new "Error: Invalid spec file. Key 'configurations' should be a hash" unless spec_hash['configurations'].is_a?(Hash)
			raise StandardError.new 'Error: Invalid spec file. Project should have at least one configuration' unless spec_hash['configurations'].keys.count > 0

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
			return Specfile.new(spec_version, [], configurations, project_base_dir) unless spec_hash.key? 'targets'
			raise StandardError.new "Error: Invalid spec file. Key 'targets' should be a hash" unless spec_hash['targets'].is_a?(Hash)

			targets = (spec_hash['targets'] || {}).map { |target_name, target_opts|
				Target.create(target_name, target_opts, project_base_dir, valid_configuration_names)
			}.compact

			return Specfile.new(spec_version, targets, configurations, project_base_dir)
		end

		# @return [String]
		def version
			@version
		end

		# @return [Array<Xcodegen::Specfile::Target>]
		def targets
			@targets
		end

		# @return [Array<Xcodegen::Specfile::Configuration>]
		def configurations
			@configurations
		end

		# @return [String]
		def base_dir
			@base_dir
		end

	end
end