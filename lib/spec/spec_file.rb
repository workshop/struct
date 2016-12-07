require 'json'
require 'semantic'
require_relative 'parser/spec_parser'

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

			class SystemFrameworkReference
				def initialize(name)
					@name = name
				end

				# @return [String]
				def name
					@name
				end
			end

			class SystemLibraryReference
				def initialize(name)
					@name = name
				end

				# @return [String]
				def name
					@name
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
			def initialize(target_name, target_type, source_dir, configurations, references, options, res_dir, file_excludes)
				@name = target_name
				@type = target_type
				@source_dir = source_dir
				@configurations = configurations
				@references = references
				@options = options
				@res_dir = res_dir || source_dir
				@file_excludes = file_excludes || []
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

			# @return [Array<String>]
			def file_excludes
				@file_excludes
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

		def self.parse(path, parser = nil)
			if parser == nil
				return Specparser.new.parse(path)
			else
				parser.parse(path)
			end
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