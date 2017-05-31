require_relative 'processor_component'

module StructCore
	module Processor
		class SchemeAnalyzeActionComponent
			include ProcessorComponent

			def process(action, action_dsl)
				output = nil

				output = process_xc_action action, action_dsl if structure == :spec
				output = process_spec_action action, action_dsl if structure == :xcodeproj

				output
			end

			def process_xc_action(action, action_dsl) end

			# @param action [StructCore::Specfile::Scheme::AnalyzeAction]
			# @param action_dsl [XCScheme::AnalyzeAction]
			def process_spec_action(action, action_dsl)
				action_dsl.build_configuration = action.build_configuration unless action.build_configuration.nil?

				action_dsl
			end
		end
	end
end