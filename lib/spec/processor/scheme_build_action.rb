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

					entry = Xcodeproj::XCScheme::BuildAction::Entry.new target
					entry.build_for_testing = action_target.testing_enabled
					entry.build_for_archiving = action_target.archiving_enabled
					entry.build_for_analyzing = action_target.analyzing_enabled
					entry.build_for_running = action_target.running_enabled
					entry.build_for_profiling = action_target.profiling_enabled
					entry
				}.compact.each { |entry|
					action_dsl.add_entry entry
				}

				action_dsl
			end
		end
	end
end