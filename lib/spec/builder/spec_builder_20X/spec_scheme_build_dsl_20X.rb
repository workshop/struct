require_relative 'spec_scheme_build_target_dsl_20X'

module StructCore
	class SpecSchemeBuildDSL20X
		attr_accessor :current_scope, :build_action

		def initialize
			@current_scope = nil
			@build_action = nil
		end

		def parallelize_builds
			@build_action.parallel = true
		end

		def build_implicit
			@build_action.build_implicit = true
		end

		def target(name = nil, &block)
			return unless name.is_a?(String) && !name.empty? && !block.nil?

			dsl = StructCore::SpecSchemeBuildTargetDSL20X.new

			@current_scope = dsl
			dsl.target = StructCore::Specfile::Scheme::BuildAction::BuildActionTarget.new name
			block.call
			@current_scope = nil

			@scheme.targets << dsl.target
		end
	end
end