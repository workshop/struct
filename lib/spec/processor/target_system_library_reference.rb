require_relative 'processor_component'

module StructCore
	module Processor
		class TargetSystemLibraryReferenceComponent
			include ProcessorComponent

			def process(ref, target_dsl = nil, group_dsl = nil)
				output = nil

				output = process_xc_ref ref if structure == :spec
				output = process_spec_ref ref, target_dsl, group_dsl if structure == :xcodeproj && !target_dsl.nil? && !group_dsl.nil?

				output
			end

			# @param ref [Xcodeproj::Project::Object::PBXFileReference]
			def process_xc_ref(ref)
				StructCore::Specfile::Target::SystemLibraryReference.new(ref.path.split('/').last)
			end

			# @param ref [StructCore::Specfile::Target::SystemLibraryReference]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param _group_dsl [Xcodeproj::Project::Object::PBXGroup]
			def process_spec_ref(ref, target_dsl, _group_dsl)
				# Filter out Foundation as it's already added by default
				target_dsl.add_system_library [ref.name]
			end
		end
	end
end