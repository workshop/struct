require_relative 'processor_component'

module StructCore
	module Processor
		class TargetLocalFrameworkReferenceComponent
			include ProcessorComponent

			def process(ref, target_dsl = nil, group_dsl = nil, embed_dsl = nil)
				output = nil

				output = process_xc_ref ref if structure == :spec
				output = process_spec_ref ref, target_dsl, group_dsl, embed_dsl if structure == :xcodeproj && !target_dsl.nil? && !group_dsl.nil? && !embed_dsl.nil?

				output
			end

			# @param ref [Xcodeproj::Project::Object::PBXFileReference]
			def process_xc_ref(ref)
				StructCore::Specfile::Target::LocalFrameworkReference.new(ref.path, nil)
			end

			# @param ref [StructCore::Specfile::Target::LocalFrameworkReference]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param group_dsl [Xcodeproj::Project::Object::PBXGroup]
			# @param embed_dsl [Xcodeproj::Project::Object::AbstractBuildPhase]
			def process_spec_ref(ref, target_dsl, group_dsl, embed_dsl)
				framework = group_dsl.new_file ref.framework_path

				# Link
				target_dsl.frameworks_build_phase.add_file_reference framework

				# Embed
				settings = ref.settings || {}
				return unless settings.key?('copy') && settings['copy'] == true

				attributes = ['RemoveHeadersOnCopy']
				attributes.push 'CodeSignOnCopy' if settings.key?('codeSignOnCopy') && settings['codeSignOnCopy'] == true

				(embed_dsl.add_file_reference framework).settings = { 'ATTRIBUTES' => attributes }
			end
		end
	end
end