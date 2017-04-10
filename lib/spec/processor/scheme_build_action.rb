require_relative 'processor_component'

module StructCore
	module Processor
		class SchemeBuildActionComponent
			include ProcessorComponent

			def process(action, action_dsl, target_dsls = nil)
				output = nil

				output = process_xc_action action, action_dsl if structure == :spec
				output = process_spec_action action, action_dsl, target_dsls if structure == :xcodeproj && !target_dsls.nil?

				output
			end

			def process_xc_action(action, action_dsl) end

			# @param action [StructCore::Specfile::Scheme::BuildAction]
			# @param action_dsl [XCScheme::BuildAction]
			# @param target_dsls [Array<Xcodeproj::Project::Object::PBXNativeTarget>]
			def process_spec_action(action, action_dsl, target_dsls)
				action_dsl.parallelize_buildables = action.parallel
				action_dsl.build_implicit_dependencies = action.build_implicit
				action.targets.map { |action_target|
					target = target_dsls.find { |t| t.name == action_target.name }
					next nil if target.nil?

					Xcodeproj::XCScheme::BuildAction::Entry.new target
				}.compact.each { |entry|
					action_dsl.add_entry entry
				}

				action_dsl
			end
		end
	end
end