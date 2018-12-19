require_relative 'processor_component'
require_relative 'scheme_environment_variables'

module StructCore
	module Processor
		class SchemeTestActionComponent
			include ProcessorComponent
			def initialize(structure, working_directory, variables_component = nil)
				super(structure, working_directory)
				@environment_variables_component = variables_component
				@environment_variables_component ||= SchemeEnvironmentVariablesProcessor.new @structure, @working_directory
			end

			def process(root_project, action, action_dsl, target_dsls = nil)
				output = nil

				output = process_xc_action action, action_dsl if structure == :spec
				output = process_spec_action root_project, action, action_dsl, target_dsls if structure == :xcodeproj && !target_dsls.nil?

				output
			end

			def process_xc_action(action, action_dsl) end

			# @param action [StructCore::Specfile::Scheme::TestAction]
			# @param action_dsl [XCScheme::TestAction]
			# @param target_dsls [Array<Xcodeproj::Project::Object::PBXNativeTarget>]
			def process_spec_action(root_project, action, action_dsl, target_dsls)
				action_dsl.build_configuration = action.build_configuration
				action_dsl.should_use_launch_scheme_args_env = action.inherit_launch_arguments
				action_dsl.code_coverage_enabled = action.code_coverage_enabled
				action_dsl.environment_variables = @environment_variables_component.process action.environment
				action.targets.map { |action_target|
					process_action_target action_target, root_project, target_dsls
				}.compact.each { |entry|
					action_dsl.add_testable entry
				}

				action_dsl
			end

			def process_action_target(action_target, root_project, target_dsls)
				if action_target['location'].nil?
					target = target_dsls.find { |t| t.name == action_target['name'] }
					return nil if target.nil?
					Xcodeproj::XCScheme::TestAction::TestableReference.new target
				else
					path = File.join(working_directory, action_target['location'])
					project = Xcodeproj::Project.open(path)
					target = project.native_targets.find { |t| t.name == action_target['name'] }
					Xcodeproj::XCScheme::TestAction::TestableReference.new(target, root_project)
				end
			end
		end
	end
end