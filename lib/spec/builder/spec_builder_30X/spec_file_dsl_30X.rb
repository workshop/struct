require_relative 'spec_configuration_dsl_30X'
require_relative 'spec_target_dsl_30X'
require_relative 'spec_variant_dsl_30X'
require_relative 'spec_scheme_dsl_30X'

module StructCore
	class SpecFileDSL30X
		def initialize
			@spec_file = nil
			@project_base_dir = nil
			@current_scope = nil
		end

		def supports_version(version)
			version.major == 3
		end

		attr_accessor :spec_file
		attr_accessor :project_base_dir

		def __spec_configuration(name = nil, &block)
			return unless name.is_a?(String) && !name.empty?
			dsl = StructCore::SpecConfigurationDSL30X.new
			dsl.configuration = StructCore::Specfile::Configuration.new(name, [], {}, nil, nil)
			unless block.nil?
				@current_scope = dsl
				block.call
				@current_scope = nil
			end

			dsl.configuration.profiles = %w(general:release ios:release)
			dsl.configuration.profiles = %w(general:debug ios:debug) if dsl.configuration.type == 'debug'

			@spec_file.configurations << dsl.configuration
		end

		def __spec_target(name, &block)
			return unless name.is_a?(String) && !name.empty? && !block.nil?
			dsl = StructCore::SpecTargetDSL30X.new
			dsl.project_configurations = @spec_file.configurations
			dsl.project_base_dir = @project_base_dir
			dsl.project = @spec_file
			dsl.target = StructCore::Specfile::Target.new(name, nil, [], [], [], [], [], [], [], [])
			@current_scope = dsl
			block.call
			@current_scope = nil

			@spec_file.targets << dsl.target
		end

		def __spec_variant(name = nil, abstract = false, &block)
			return unless name.is_a?(String) && !name.empty? && [true, false].include?(abstract) && !block.nil?
			dsl = StructCore::SpecVariantDSL30X.new
			dsl.project_configurations = @spec_file.configurations
			dsl.project_base_dir = @project_base_dir
			dsl.project_target_names = @spec_file.targets.map(&:name)
			dsl.project = @spec_file
			dsl.variant = StructCore::Specfile::Variant.new(name, [], abstract)
			@current_scope = dsl
			block.call
			@current_scope = nil

			@spec_file.variants << dsl.variant
		end

		def __spec_scheme(name = nil, &block)
			return unless name.is_a?(String) && !name.empty? && !block.nil?

			dsl = StructCore::SpecSchemeDSL30X.new
			dsl.scheme = StructCore::Specfile::Scheme.new name
			dsl.project = @spec_file
			@current_scope = dsl
			block.call
			@current_scope = nil

			@spec_file.schemes << dsl.scheme
		end

		def pre_generate(&block)
			@spec_file.pre_generate_script = StructCore::Specfile::HookBlockScript.new block
		end

		def post_generate(&block)
			@spec_file.post_generate_script = StructCore::Specfile::HookBlockScript.new block
		end

		def __spec_script(name = nil, location = nil)
			return unless name.is_a?(String) && !name.empty? && location.is_a?(String) && !location.empty?

			@spec_file.scripts ||= {}
			@spec_file.scripts[name] = StructCore::Specfile::HookScript.new location
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(method, *args, &block)
			if @current_scope.nil? && method == :configuration
				send('__spec_configuration', *args, &block)
			elsif @current_scope.nil? && method == :target
				send('__spec_target', *args, &block)
			elsif @current_scope.nil? && method == :variant
				send('__spec_variant', *args, &block)
			elsif @current_scope.nil? && method == :scheme
				send('__spec_scheme', *args, &block)
			elsif @current_scope.nil? && method == :script
				send('__spec_script', *args, &block)
			else
				@current_scope.send(method, *args, &block)
			end
		end
	end
end