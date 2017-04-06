require 'json'
require 'semantic'
require_relative 'parser/spec_parser'
require_relative 'writer/spec_writer'

module StructCore
	class Specfile
		class Configuration
			def initialize(name, profiles = [], overrides = {}, type = nil, source = nil)
				@name = name
				@profiles = profiles
				@overrides = overrides
				@raw_type = type
				@source = source
			end

			# @return [String]
			def type
				if @name == 'debug'
					'debug'
				elsif @name == 'release'
					'release'
				else
					@raw_type
				end
			end

			attr_writer :type
			attr_accessor :name
			attr_accessor :profiles
			attr_accessor :overrides
			attr_accessor :raw_type
			attr_accessor :source
		end

		class Target
			class Configuration
				def initialize(name, settings = {}, profiles = [], source = nil)
					@name = name
					@settings = settings
					@profiles = profiles || []
					@source = source
				end

				attr_accessor :name
				attr_accessor :settings
				attr_accessor :profiles
				attr_accessor :source
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

			class LocalLibraryReference
				def initialize(library_path, settings)
					@library_path = library_path
					@settings = settings
				end

				attr_accessor :library_path
				attr_accessor :settings
			end

			class FileOption
				def initialize(glob, flags)
					@glob = glob
					@flags = flags
				end

				attr_accessor :glob
				attr_accessor :flags
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
			# @param options [Array<StructCore::Specfile::Target::FileOption>]
			# @param res_dir [Array<String>]
			# @param file_excludes [Array<String>]
			# @param postbuild_run_scripts [Array<StructCore::Specfile::Target::RunScript>]
			# @param prebuild_run_scripts [Array<StructCore::Specfile::Target::RunScript>]
			def initialize(
				target_name, target_type, source_dir = [], configurations = [], references = [],
				options = [], res_dir = [], file_excludes = [], postbuild_run_scripts = [],
				prebuild_run_scripts = []
			)
				@name = target_name
				@type = target_type
				@source_dir = []
				unless source_dir.nil?
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
				@postbuild_run_scripts = postbuild_run_scripts || []
				@prebuild_run_scripts = prebuild_run_scripts || []
			end

			attr_accessor :name
			attr_accessor :type
			attr_accessor :source_dir
			attr_accessor :configurations
			attr_accessor :references
			attr_accessor :options
			attr_accessor :res_dir
			attr_accessor :file_excludes
			attr_accessor :prebuild_run_scripts
			attr_accessor :postbuild_run_scripts

			def run_scripts=(s)
				@postbuild_run_scripts = s
			end

			def run_scripts
				@postbuild_run_scripts
			end
		end

		class Variant
			def initialize(variant_name, targets, abstract)
				@name = variant_name
				@targets = targets
				@abstract = abstract
			end

			attr_accessor :name
			attr_accessor :targets
			attr_accessor :abstract
		end

		class HookScript
			def initialize(script_path)
				@script_path = script_path
			end

			attr_accessor :script_path
		end

		class HookBlockScript
			def initialize(block)
				@block = block
			end

			attr_accessor :block
		end

		class Scheme
			def initialize(name, build_action = nil, test_action = nil, launch_action = nil, archive_action = nil, analyze_action = nil, profile_action = nil)
				@name = name
				@build_action = build_action
				@test_action = test_action
				@launch_action = launch_action
				@archive_action = archive_action
				@analyze_action = analyze_action
				@profile_action = profile_action
			end

			attr_accessor :name, :profile_action, :build_action, :test_action, :analyze_action, :launch_action, :archive_action

			class BuildAction
				def initialize(targets = [], parallel = false, build_implicit = false)
					@targets = targets
					@parallel = parallel
					@build_implicit = build_implicit
				end

				attr_accessor :build_implicit, :targets, :parallel

				class BuildActionTarget
					def initialize(name, archiving_enabled = false, running_enabled = false, profiling_enabled = false, testing_enabled = false)
						@name = name
						@archiving_enabled = archiving_enabled
						@running_enabled = running_enabled
						@profiling_enabled = profiling_enabled
						@testing_enabled = testing_enabled
					end

					attr_accessor :name, :archiving_enabled, :running_enabled, :profiling_enabled, :testing_enabled
				end
			end

			class TestAction
				def initialize(build_configuration, targets = [], inherit_launch_arguments = false, code_coverage_enabled = false, environment = {})
					@build_configuration = build_configuration
					@targets = targets
					@inherit_launch_arguments = inherit_launch_arguments
					@code_coverage_enabled = code_coverage_enabled
					@environment = environment
				end

				attr_accessor :build_configuration, :code_coverage_enabled, :inherit_launch_arguments, :environment, :targets
			end

			class LaunchAction
				def initialize(target_name, simulate_location = false, arguments = '', environment = {})
					@target_name = target_name
					@simulate_location = simulate_location
					@arguments = arguments
					@environment = environment
				end

				attr_accessor :environment, :simulate_location, :arguments, :target_name
			end

			class ArchiveAction
				def initialize(archive_name, reveal = false)
					@archive_name = archive_name
					@reveal = reveal
				end

				attr_accessor :reveal, :archive_name
			end

			class AnalyzeAction
				def initialize(configuration = {})
					@configuration = configuration
				end

				attr_accessor :configuration
			end

			class ProfileAction
				def initialize(target_name, configuration = {}, inherit_environment = false)
					@target_name = target_name
					@configuration = configuration
					@inherit_environment = inherit_environment
				end

				attr_accessor :inherit_environment, :configuration, :target_name
			end
		end

		# @param version [Semantic::Version, String]
		# @param targets [Array<StructCore::Specfile::Target>]
		# @param configurations [Array<StructCore::Specfile::Configuration>]
		# @param variants [Array<StructCore::Specfile::Variant>]
		# @param pre_generate_script [StructCore::Specfile::HookScript, StructCore::Specfile::HookBlockScript]
		# @param post_generate_script [StructCore::Specfile::HookScript, StructCore::Specfile::HookBlockScript]
		def initialize(version = LATEST_SPEC_VERSION, targets = [], configurations = [], variants = [], base_dir = Dir.pwd, includes_pods = false, pre_generate_script = nil, post_generate_script = nil, schemes = [])
			@version = LATEST_SPEC_VERSION
			@version = version if version.is_a?(Semantic::Version)
			@version = Semantic::Version.new(version) if version.is_a?(String)
			@targets = targets
			@variants = variants
			@configurations = configurations
			@base_dir = base_dir
			@includes_pods = includes_pods
			@pre_generate_script = pre_generate_script
			@post_generate_script = post_generate_script
			@schemes = schemes
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
		attr_accessor :includes_pods
		attr_accessor :pre_generate_script
		attr_accessor :post_generate_script
		attr_accessor :schemes
	end
end