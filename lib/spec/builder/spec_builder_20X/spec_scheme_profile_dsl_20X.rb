module StructCore
	class SpecSchemeProfileDSL20X
		attr_accessor :current_scope, :profile_action

		def initialize
			@current_scope = nil
			@profile_action = nil
		end

		def inherit_environment
			@profile_action.inherit_environment = true
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