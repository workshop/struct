module StructCore
	class SpecSchemeProfileDSL30X
		attr_accessor :current_scope, :profile_action, :project

		def initialize
			@current_scope = nil
			@profile_action = nil
			@project = nil
		end

		def inherit_environment
			@profile_action.inherit_environment = true
		end

		def build_configuration(args = '')
			return if args.nil? || !args.is_a?(String)
			@profile_action.build_configuration = args if @project.version.major == 2 && @project.version.minor >= 1
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