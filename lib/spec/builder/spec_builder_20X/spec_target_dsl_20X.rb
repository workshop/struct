require 'deep_clone'
require_relative 'spec_target_configuration_dsl_20X'
require_relative 'spec_target_project_ref_dsl_20X'
require_relative 'spec_target_script_dsl_20X'
require_relative '../../../utils/ruby_2_0_monkeypatches'

module StructCore
	class SpecTargetDSL20X
		def initialize
			@target = nil
			@type = nil
			@raw_type = nil
			@profiles = []
			@project_configurations = []
			@project_base_dir = nil
			@project = nil
			@current_scope = nil
			@base_overrides = {}
		end

		attr_accessor :project_configurations
		attr_accessor :project_base_dir
		attr_accessor :target
		attr_accessor :project

		def type(type = nil)
			parse_raw_type(type) if type.is_a?(String) || type.is_a?(Symbol)
			parse_hash_type(type) if type.is_a?(Hash)
		end

		def parse_raw_type(type)
			@type = type
			@type = ":#{type}" if type.is_a?(Symbol)
			# : at the start of the type is shorthand for 'com.apple.product-type.'
			if @type.start_with? ':'
				@type[0] = ''
				@raw_type = @type
				@type = "com.apple.product-type.#{@type}"
			else
				@raw_type = @type
			end

			@profiles << @raw_type
			@target.type = @type
		end

		def parse_hash_type(type)
			@type = type[:uuid]
			return if @type.nil?

			@raw_type = @type
			@profiles << @raw_type
			@target.type = @type
		end

		def platform(platform = nil)
			return unless platform.is_a?(String) || platform.is_a?(Symbol)
			# TODO: Add support for 'tvos'
			platform = platform.to_s if platform.is_a?(Symbol)
			unless %w(ios mac watch).include? platform
				puts Paint["Warning: Target #{target_name} specifies unrecognised platform '#{platform}'. Ignoring...", :yellow]
				return
			end

			@profiles << "platform:#{platform}"
		end

		def configuration(name = nil, &block)
			dsl = StructCore::SpecTargetConfigurationDSL20X.new
			@current_scope = dsl

			if name.nil?
				dsl.configuration = StructCore::Specfile::Target::Configuration.new nil, {}, []
				block.call
				@current_scope = nil

				config = dsl.configuration
				config.settings.merge! @base_overrides
				config.profiles = @profiles if config.source.nil? || config.source.empty?
				@target.configurations = @project_configurations.map { |project_config|
					target_config = DeepClone.clone config
					target_config.name = project_config.name
					target_config
				}
			else
				dsl.configuration = StructCore::Specfile::Target::Configuration.new name, {}, []
				block.call
				@current_scope = nil

				config = dsl.configuration
				config.settings.merge! @base_overrides
				config.profiles = @profiles if config.source.nil? || config.source.empty?

				unless config.name == '$base'
					@target.configurations << config
					return
				end

				@base_overrides = config.settings

				@target.configurations.each { |c|
					c.settings ||= {}
					c.settings.merge! @base_overrides
				}
			end
		end

		def source_dir(path = nil)
			return unless path.is_a?(String) && !path.empty?
			@target.source_dir << File.join(@project_base_dir, path)
		end

		def i18n_resource_dir(path = nil)
			return unless path.is_a?(String) && !path.empty?
			@target.res_dir << File.join(@project_base_dir, path)
		end

		def system_reference(reference = nil)
			return unless reference.is_a?(String) && !reference.empty?
			@target.references << StructCore::Specfile::Target::SystemFrameworkReference.new(reference.sub('.framework', '')) if reference.end_with? '.framework'
			@target.references << StructCore::Specfile::Target::SystemLibraryReference.new(reference) unless reference.end_with? '.framework'
		end

		def target_reference(reference = nil, settings = nil)
			return unless reference.is_a?(String) && !reference.empty?
			settings ||= {}
			reference = StructCore::Specfile::Target::TargetReference.new(reference)

			if @project.version.minor >= 2
				# Convert any keys to hashes
				reference.settings = settings
				reference.settings = reference.settings.map { |k, v| [k.to_s, v] }.to_h
			end

			@target.references << reference
		end

		def framework_reference(reference = nil, settings = nil)
			return unless reference.is_a?(String) && !reference.empty?

			settings ||= {}
			reference = StructCore::Specfile::Target::LocalFrameworkReference.new(reference, settings)

			# Convert any keys to hashes
			reference.settings = reference.settings.map { |k, v| [k.to_s, v] }.to_h
			@target.references << reference
		end

		def library_reference(reference = nil)
			return unless reference.is_a?(String) && !reference.empty?
			reference = StructCore::Specfile::Target::LocalLibraryReference.new(reference, {})

			@target.references << reference
		end

		def project_framework_reference(project = nil, &block)
			return unless project.is_a?(String) && !project.empty? && !block.nil?

			settings = {}
			settings['frameworks'] = []

			dsl = StructCore::SpecTargetProjectRefDSL20X.new
			dsl.reference = StructCore::Specfile::Target::FrameworkReference.new(project, settings)
			dsl.instance_eval(&block)

			@target.references << dsl.reference unless dsl.reference.nil? || dsl.reference.settings['frameworks'].empty?
		end

		def include_cocoapods
			@project.includes_pods = true
		end

		def exclude_files_matching(glob = nil)
			return unless glob.is_a?(String) && !glob.empty?
			@target.file_excludes << glob
		end

		def script_prebuild(script_path = nil, &block)
			return unless script_path.is_a?(String) && !script_path.empty?
			script = StructCore::Specfile::Target::RunScript.new(script_path)

			if !block.nil? && @project.version.minor >= 2
				dsl = SpecTargetScriptDSL20X.new
				@current_scope = dsl
				dsl.script = script
				block.call
				@current_scope = nil
			end

			@target.prebuild_run_scripts << script
		end

		def __script(script_path = nil, &block)
			return unless script_path.is_a?(String) && !script_path.empty?
			script = StructCore::Specfile::Target::RunScript.new(script_path)

			if !block.nil? && @project.version.minor >= 2
				dsl = SpecTargetScriptDSL20X.new
				@current_scope = dsl
				dsl.script = script
				block.call
				@current_scope = nil
			end

			@target.postbuild_run_scripts << script
		end

		def script_postbuild(script_path = nil, &block)
			return unless script_path.is_a?(String) && !script_path.empty?
			script = StructCore::Specfile::Target::RunScript.new(script_path)

			if !block.nil? && @project.version.minor >= 2
				dsl = SpecTargetScriptDSL20X.new
				@current_scope = dsl
				dsl.script = script
				block.call
				@current_scope = nil
			end

			@target.postbuild_run_scripts << script
		end

		def source_options(glob = nil, flags = nil)
			return unless glob.is_a?(String) && !glob.empty? && flags.is_a?(String)
			@target.options << StructCore::Specfile::Target::FileOption.new(glob, flags)
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(method, *args, &block)
			if @current_scope.nil? && method == :script
				send('__script', *args, &block)
			else
				return if @current_scope.nil?
				@current_scope.send(method, *args, &block)
			end
		end
	end
end