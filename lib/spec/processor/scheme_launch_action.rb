require_relative 'processor_component'
require_relative 'scheme_environment_variables'
require_relative 'scheme_arguments'

module StructCore
	module Processor
		class SchemeLaunchActionComponent
			include ProcessorComponent
			def initialize(structure, working_directory, variables_component = nil, arguments_component = nil)
				super(structure, working_directory)
				@environment_variables_component = variables_component
				@environment_variables_component ||= SchemeEnvironmentVariablesProcessor.new @structure, @working_directory
				@arguments_component = arguments_component
				@arguments_component ||= SchemeArgumentsProcessor.new @structure, @working_directory
			end

			def process(action, action_dsl, targets = nil)
				output = nil

				output = process_xc_action action, action_dsl if structure == :spec
				output = process_spec_action action, action_dsl, targets if structure == :xcodeproj && !targets.nil?

				output
			end

			def process_xc_action(action, action_dsl) end

			# @param action [StructCore::Specfile::Scheme::LaunchAction]
			# @param action_dsl [XCScheme::LaunchAction]
			# @param targets [Array<StructCore::Specfile::Target>]
			def process_spec_action(action, action_dsl, targets)
				runnable = nil
				target = targets.find { |t| t.name == action.target_name }
				runnable = Xcodeproj::XCScheme::BuildableProductRunnable.new target unless target.nil?

				action_dsl.allow_location_simulation = action.simulate_location
				action_dsl.build_configuration = action.build_configuration unless action.build_configuration.nil?
				action_dsl.environment_variables = @environment_variables_component.process action.environment
				action_dsl.command_line_arguments = @arguments_component.process action.arguments
				action_dsl.buildable_product_runnable = runnable unless runnable.nil?

				action_dsl
			end
		end
	end
end