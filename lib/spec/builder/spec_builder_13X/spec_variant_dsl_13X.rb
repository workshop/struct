require_relative 'spec_target_dsl_13X'

module StructCore
	class SpecVariantDSL13X
		def initialize
			@variant = nil
			@project_configurations = []
			@project_base_dir = nil
			@project_target_names = []
			@project = nil
			@current_scope = nil
		end

		attr_accessor :variant
		attr_accessor :project_configurations
		attr_accessor :project_base_dir
		attr_accessor :project_target_names
		attr_accessor :project

		def abstract
			@variant.abstract = true
		end

		def target(name = nil, &block)
			return unless name.is_a?(String) && !name.empty? && !block.nil? && @project_target_names.include?(name)
			dsl = StructCore::SpecTargetDSL13X.new
			dsl.project_configurations = @project_configurations
			dsl.project_base_dir = @project_base_dir
			dsl.target = StructCore::Specfile::Target.new(name, nil, [], [], [], [], [], [], [], [])
			dsl.project = @project
			@current_scope = dsl
			block.call
			@current_scope = nil

			@variant.targets << dsl.target
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(method, *args, &block)
			return if @current_scope.nil?
			@current_scope.send(method, *args, &block)
		end
	end
end