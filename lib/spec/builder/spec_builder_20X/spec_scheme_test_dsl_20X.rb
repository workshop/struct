require_relative 'spec_scheme_test_environment_dsl_20X'

module StructCore
	class SpecSchemeTestDSL20X
		attr_accessor :current_scope, :test_action, :project

		def initialize
			@current_scope = nil
			@test_action = nil
			@project = nil
		end

		def target(name = nil)
			return unless name.is_a?(String) && !name.empty?
			@test_action.targets ||= []
			@test_action.targets << name
		end

		def inherit_launch_arguments
			@test_action.inherit_launch_arguments = true
		end

		def enable_code_coverage
			@test_action.code_coverage_enabled = true
		end

		def environment(&block)
			return if block.nil?

			dsl = StructCore::SpecSchemeTestEnvironmentDSL20X.new

			@current_scope = dsl
			dsl.environment = {}
			block.call
			@current_scope = nil

			@test_action.environment = dsl.environment
		end

		def build_configuration(args = '')
			return if args.nil? || !args.is_a?(String)
			@test_action.build_configuration = args if @project.version.major == 2 && @project.version.minor >= 1
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