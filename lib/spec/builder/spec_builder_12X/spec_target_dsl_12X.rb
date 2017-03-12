require 'deep_clone'
require_relative 'spec_target_configuration_dsl_12X'
require_relative 'spec_target_project_ref_dsl_12X'

module StructCore
	class SpecTargetDSL12X
		def initialize
			@target = nil
			@type = nil
			@raw_type = nil
			@profiles = []
			@project_configurations = []
			@project_base_dir = nil
		end

		attr_accessor :project_configurations
		attr_accessor :project_base_dir
		attr_accessor :target

		def type(type)
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

		def profile(profile)
			return unless profile.is_a?(String) && !profile.empty?
			@profiles << profile
		end

		def platform(platform)
			return unless platform.is_a?(String) || platform.is_a?(Symbol)
			# TODO: Add support for 'tvos', 'watchos'
			platform = platform.to_s if platform.is_a?(Symbol)
			unless %w(ios mac).include? platform
				puts Paint["Warning: Target #{target_name} specifies unrecognised platform '#{platform}'. Ignoring...", :yellow]
				return
			end

			@profiles << "platform:#{platform}"
		end

		def configuration(name = nil, &block)
			dsl = StructCore::SpecTargetConfigurationDSL12X.new

			if name.nil?
				dsl.configuration = StructCore::Specfile::Target::Configuration.new nil, {}, []
				dsl.instance_eval(&block)

				config = dsl.configuration
				config.profiles = @profiles
				@target.configurations = @project_configurations.map { |project_config|
					target_config = DeepClone.clone config
					target_config.name = project_config.name
					target_config
				}
			else
				dsl.configuration = StructCore::Specfile::Target::Configuration.new name, {}, []
				dsl.instance_eval(&block)

				config = dsl.configuration
				return if config.profiles.empty? && (config.source.nil? || config.source.empty?)

				config.profiles = @profiles
				@target.configurations << config
			end
		end

		def source_dir(path)
			return unless path.is_a?(String) && !path.empty?
			@target.source_dir << File.join(@project_base_dir, path)
		end

		def i18n_resource_dir(path)
			return unless path.is_a?(String) && !path.empty?
			@target.res_dir << File.join(@project_base_dir, path)
		end

		def system_reference(reference)
			return unless reference.is_a?(String) && !reference.empty?
			@target.references << StructCore::Specfile::Target::SystemFrameworkReference.new(reference.sub('.framework', '')) if reference.end_with? '.framework'
			@target.references << StructCore::Specfile::Target::SystemLibraryReference.new(reference) unless reference.end_with? '.framework'
		end

		def target_reference(reference)
			return unless reference.is_a?(String) && !reference.empty?
			@target.references << StructCore::Specfile::Target::TargetReference.new(reference)
		end

		def framework_reference(reference, settings = nil)
			return unless reference.is_a?(String) && !reference.empty?

			settings ||= {}
			reference = StructCore::Specfile::Target::LocalFrameworkReference.new(reference, settings)

			# Convert any keys to hashes
			reference.settings = reference.settings.map { |k, v| [k.to_s, v] }.to_h
			@target.references << reference
		end

		def project_framework_reference(project, &block)
			return unless project.is_a?(String) && !project.empty? && !block.nil?

			settings = {}
			settings['frameworks'] = []

			dsl = StructCore::SpecTargetProjectRefDSL12X.new
			dsl.reference = StructCore::Specfile::Target::FrameworkReference.new(project, settings)
			dsl.instance_eval(&block)

			@target.references << dsl.reference unless dsl.reference.nil? || dsl.reference.settings['frameworks'].empty?
		end

		def exclude_files_matching(glob)
			return unless glob.is_a?(String) && !glob.empty?
			@target.file_excludes << glob
		end

		def script_prebuild(script_path)
			return unless script_path.is_a?(String) && !script_path.empty?
			@target.prebuild_run_scripts << StructCore::Specfile::Target::RunScript.new(script_path)
		end

		def script(script_path)
			return unless script_path.is_a?(String) && !script_path.empty?
			@target.postbuild_run_scripts << StructCore::Specfile::Target::RunScript.new(script_path)
		end

		def script_postbuild(script_path)
			return unless script_path.is_a?(String) && !script_path.empty?
			@target.postbuild_run_scripts << StructCore::Specfile::Target::RunScript.new(script_path)
		end

		def respond_to_missing?(_, _)
			true
		end

		# rubocop:disable Style/MethodMissing
		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
		# rubocop:enable Style/MethodMissing
	end
end