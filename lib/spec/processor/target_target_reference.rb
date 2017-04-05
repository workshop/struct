require_relative 'processor_component'

module StructCore
	module Processor
		class TargetTargetReferenceComponent
			include ProcessorComponent

			def process(reference, target_dsl = nil, dsl = nil)
				output = nil

				output = process_xc_reference reference if structure == :spec
				output = process_spec_reference reference, target_dsl, dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil?

				output
			end

			# @param reference [Xcodeproj::Project::Object::PBXNativeTarget]
			def process_xc_reference(reference)
				StructCore::Specfile::Target::TargetReference.new reference.name
			end

			# @param reference [StructCore::Specfile::Target::TargetReference]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_reference(reference, target_dsl, dsl)
				other_target = dsl.targets.find { |t| t.name == reference.target_name }
				return nil if other_target.nil?

				target_dsl.add_dependency other_target
			end
		end
	end
end