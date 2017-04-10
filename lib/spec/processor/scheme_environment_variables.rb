require_relative 'processor_component'

module StructCore
	module Processor
		class SchemeEnvironmentVariablesProcessor
			include ProcessorComponent

			def process(variables)
				output = nil

				output = process_xc_variables variables if structure == :spec
				output = process_spec_variables variables if structure == :xcodeproj

				output
			end

			def process_xc_variables(variables) end

			# @param variables [Hash]
			def process_spec_variables(variables)
				Xcodeproj::XCScheme::EnvironmentVariables.new variables.map { |k, v|
					Xcodeproj::XCScheme::EnvironmentVariable.new(key: k, value: v)
				}
			end
		end
	end
end