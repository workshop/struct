require_relative 'spec_scheme_launch_environment_dsl_30X'

module StructCore
	class SpecSchemeLaunchDSL30X
		attr_accessor :current_scope, :launch_action, :project

		def initialize
			@current_scope = nil
			@launch_action = nil
			@project = nil
		end

		def enable_location_simulation
			@launch_action.simulate_location = true
		end

		def arguments(args = '')
			return if args.nil? || !args.is_a?(String)
			@launch_action.arguments = args
		end

		def environment(&block)
			return if block.nil?

			dsl = StructCore::SpecSchemeLaunchEnvironmentDSL30X.new

			@current_scope = dsl
			dsl.environment = {}
			block.call
			@current_scope = nil

			@launch_action.environment = dsl.environment
		end

		def build_configuration(args = '')
			return if args.nil? || !args.is_a?(String)
			@launch_action.build_configuration = args
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