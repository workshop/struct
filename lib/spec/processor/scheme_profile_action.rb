require_relative 'processor_component'

module StructCore
	module Processor
		class SchemeProfileActionComponent
			include ProcessorComponent

			def process(action, action_dsl, targets = nil)
				output = nil

				output = process_xc_action action, action_dsl if structure == :spec
				output = process_spec_action action, action_dsl, targets if structure == :xcodeproj && !targets.nil?

				output
			end

			def process_xc_action(action, action_dsl) end

			# @param action [StructCore::Specfile::Scheme::ProfileAction]
			# @param action_dsl [XCScheme::ProfileAction]
			# @param targets [Array<StructCore::Specfile::Target>]
			def process_spec_action(action, action_dsl, targets)
				runnable = nil
				target = targets.find { |t| t.name == action.target_name }
				runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new target unless target.nil?

				action_dsl.should_use_launch_scheme_args_env = action.inherit_environment
				action_dsl.buildable_product_runnable = runnable unless runnable.nil?

				action_dsl
			end
		end
	end
end