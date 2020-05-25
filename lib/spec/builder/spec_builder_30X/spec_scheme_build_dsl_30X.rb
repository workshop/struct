require_relative 'spec_scheme_build_target_dsl_30X'

module StructCore
	class SpecSchemeBuildDSL30X
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

			dsl = StructCore::SpecSchemeBuildTargetDSL30X.new

			@current_scope = dsl
			dsl.target = StructCore::Specfile::Scheme::BuildAction::BuildActionTarget.new name
			block.call
			@current_scope = nil

			@build_action.targets << dsl.target
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