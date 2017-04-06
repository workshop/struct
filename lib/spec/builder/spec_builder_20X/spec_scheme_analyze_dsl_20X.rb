require_relative 'spec_scheme_analyze_configuration_dsl_20X'

module StructCore
	class SpecSchemeAnalyzeDSL20X
		attr_accessor :analyze_action

		def initialize
			@analyze_action = nil
			@current_scope = nil
		end

		def configuration(&block)
			return if block.nil?

			dsl = StructCore::SpecSchemeAnalyzeConfigurationDSL20X.new

			@current_scope = dsl
			dsl.configuration = {}
			block.call
			@current_scope = nil

			@analyze_action.configuration = dsl.configuration
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