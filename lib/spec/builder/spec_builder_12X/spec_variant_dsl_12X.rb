require_relative 'spec_target_dsl_12X'

module StructCore
	class SpecVariantDSL12X
		def initialize
			@variant = nil
			@project_configurations = []
			@project_base_dir = nil
		end

		attr_accessor :variant
		attr_accessor :project_configurations
		attr_accessor :project_base_dir

		def target(name, &block)
			dsl = StructCore::SpecTargetDSL12X.new
			dsl.project_configurations = @project_configurations
			dsl.project_base_dir = @project_base_dir
			dsl.target = StructCore::Specfile::Target.new(name, nil, [], [], [], [], [], [], [], [])
			dsl.instance_eval(&block)

			@variant.targets << dsl.target
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