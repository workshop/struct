require_relative 'processor_component'

module StructCore
	module Processor
		class SchemeArchiveActionComponent
			include ProcessorComponent

			def process(action, action_dsl)
				output = nil

				output = process_xc_action action, action_dsl if structure == :spec
				output = process_spec_action action, action_dsl if structure == :xcodeproj

				output
			end

			def process_xc_action(action, action_dsl) end

			# @param action [StructCore::Specfile::Scheme::ArchiveAction]
			# @param action_dsl [XCScheme::ArchiveAction]
			def process_spec_action(action, action_dsl)
				action_dsl.custom_archive_name = action.archive_name
				action_dsl.reveal_archive_in_organizer = action.reveal

				action_dsl
			end
		end
	end
end