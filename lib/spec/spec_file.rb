require 'json'
require 'semantic'
require_relative 'parser/spec_parser'
require_relative 'writer/spec_writer'

module StructCore
	class Specfile
		class Configuration
			def initialize(name, profiles, overrides, type = nil)
				@name = name
				@profiles = profiles
				@overrides = overrides
				@type = type
			end

			# @return [String]
			def type
				if name == 'debug'
					'debug'
				elsif name == 'release'
					'release'
				else
					@type
				end
			end

			attr_writer :type
			attr_accessor :name
			attr_accessor :profiles
			attr_accessor :overrides
		end

		class Target
			class Configuration
				def initialize(name, settings, profiles = nil)
					@name = name
					@settings = settings
					@profiles = profiles || []
				end

				attr_accessor :name
				attr_accessor :settings
				attr_accessor :profiles
			end

			class TargetReference
				def initialize(target_name)
					@target_name = target_name
				end

				attr_accessor :target_name
			end

			class SystemFrameworkReference
				def initialize(name)
					@name = name
				end

				attr_accessor :name
			end

			class SystemLibraryReference
				def initialize(name)
					@name = name
				end

				attr_accessor :name
			end

			class FrameworkReference
				def initialize(project_path, settings)
					@project_path = project_path
					@settings = settings
				end

				attr_accessor :project_path
				attr_accessor :settings
			end

			class LocalFrameworkReference
				def initialize(framework_path, settings)
					@framework_path = framework_path
					@settings = settings
				end

				attr_accessor :framework_path
				attr_accessor :settings
			end

			class FileOption
				def initialize(glob, options)
					@glob = glob
					@options = options
				end

				attr_accessor :glob
				attr_accessor :options
			end

			class RunScript
				def initialize(script_path)
					@script_path = script_path
				end

				attr_accessor :script_path
			end

			# @param target_name [String]
			# @param target_type [String]
			# @param source_dir [Array<String>]
			# @param configurations [Array<StructCore::Specfile::Target::Configuration>]
			# @param references [Array<StructCore::Specfile::Target::FrameworkReference>]
			# @param options [Array<StructCore::Specfile::Target::FileOption, StructCore::Specfile::Target::FrameworkOption>]
			# @param res_dir [Array<String>]
			# @param file_excludes [Array<String>]
			# @param run_scripts [Array<StructCore::Specfile::Target::RunScript>]
			def initialize(target_name, target_type, source_dir, configurations, references, options, res_dir, file_excludes, run_scripts = [])
				@name = target_name
				@type = target_type
				@source_dir = []
				if source_dir.nil?
					@source_dir = [source_dir]
					@source_dir = [].unshift(*source_dir) if source_dir.is_a? Array
				end
				@configurations = configurations
				@references = references
				@options = options
				if !res_dir.nil?
					@res_dir = [res_dir]
					@res_dir = [].unshift(*res_dir) if res_dir.is_a? Array
				else
					@res_dir = @source_dir
				end
				@file_excludes = file_excludes || []
				@run_scripts = run_scripts || []
			end

			attr_accessor :name
			attr_accessor :type
			attr_accessor :source_dir
			attr_accessor :configurations
			attr_accessor :references
			attr_accessor :options
			attr_accessor :res_dir
			attr_accessor :file_excludes
			attr_accessor :run_scripts
		end

		class Variant
			class Target
				# @param target_name [String]
				# @param target_type [String]
				# @param source_dir [String]
				# @param configurations [Array<StructCore::Specfile::Target::Configuration>]
				# @param references [Array<StructCore::Specfile::Target::FrameworkReference>]
				# @param options [Array<StructCore::Specfile::Target::FileOption, StructCore::Specfile::Target::FrameworkOption>]
				# @param res_dir [String]
				# @param file_excludes [String]
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

				attr_accessor :name
				attr_accessor :type
				attr_accessor :source_dir
				attr_accessor :configurations
				attr_accessor :references
				attr_accessor :options
				attr_accessor :res_dir
				attr_accessor :file_excludes
			end

			def initialize(variant_name, targets, abstract)
				@name = variant_name
				@targets = targets
				@abstract = abstract
			end

			attr_accessor :name
			attr_accessor :targets
			attr_accessor :abstract
		end

		# @param version [Semantic::Version]
		# @param targets [Array<StructCore::Specfile::Target>]
		# @param configurations [Array<StructCore::Specfile::Configuration>]
		def initialize(version, targets, configurations, variants, base_dir)
			@version = version
			@targets = targets
			@variants = variants
			@configurations = configurations
			@base_dir = base_dir
		end

		# @return StructCore::Specfile
		def self.parse(path, parser = nil)
			return Specparser.new.parse(path) if parser.nil?
			parser.parse(path)
		end

		def write(path, writer = nil)
			return Specwriter.new.write_spec(self, path) if writer.nil?
			writer.write_spec(self, path)
		end

		attr_accessor :version
		attr_accessor :targets
		attr_accessor :variants
		attr_accessor :configurations
		attr_accessor :base_dir
	end
end