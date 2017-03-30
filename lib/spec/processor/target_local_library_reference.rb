require_relative 'processor_component'

module StructCore
	module Processor
		class TargetLocalLibraryReferenceComponent
			include ProcessorComponent

			def process(ref, target_dsl = nil, group_dsl = nil)
				output = nil

				output = process_xc_ref ref if structure == :spec
				output = process_spec_ref ref, target_dsl, group_dsl if structure == :xcodeproj && !target_dsl.nil? && !group_dsl.nil?

				output
			end

			def process_xc_ref(ref) end

			# @param ref [StructCore::Specfile::Target::LocalLibraryReference]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param group_dsl [Xcodeproj::Project::Object::PBXGroup]
			def process_spec_ref(ref, target_dsl, group_dsl)
				framework = group_dsl.new_file ref.library_path

				# Link
				target_dsl.frameworks_build_phase.add_file_reference framework
			end
		end
	end
end