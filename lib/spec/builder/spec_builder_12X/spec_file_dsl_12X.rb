require_relative 'spec_configuration_dsl_12X'
require_relative 'spec_target_dsl_12X'
require_relative 'spec_variant_dsl_12X'

module StructCore
	class SpecFileDSL12X
		def initialize
			@spec_file = nil
			@project_base_dir = nil
			@current_scope = nil
		end

		def supports_version(version)
			version.major == 1 && version.minor == 2
		end

		attr_accessor :spec_file
		attr_accessor :project_base_dir

		def __spec_configuration(name = nil, &block)
			return unless name.is_a?(String) && !name.empty? && !block.nil?
			dsl = StructCore::SpecConfigurationDSL12X.new
			dsl.configuration = StructCore::Specfile::Configuration.new(name, [], {}, nil, nil)
			@current_scope = dsl
			block.call
			@current_scope = nil

			@spec_file.configurations << dsl.configuration
		end

		def __spec_target(name, &block)
			return unless name.is_a?(String) && !name.empty? && !block.nil?
			dsl = StructCore::SpecTargetDSL12X.new
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
			dsl = StructCore::SpecVariantDSL12X.new
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

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(method, *args, &block)
			if @current_scope.nil? && method == :configuration
				self.send('__spec_configuration', *args, &block)
			elsif @current_scope.nil? && method == :target
				self.send('__spec_target', *args, &block)
			elsif @current_scope.nil? && method == :variant
				self.send('__spec_variant', *args, &block)
			else
				@current_scope.send(method, *args, &block)
			end
		end
	end
end