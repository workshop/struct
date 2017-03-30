require_relative 'processor_component'
require_relative 'target_system_framework_reference'
require_relative 'target_system_library_reference'
require_relative 'target_local_framework_reference'
require_relative 'target_local_library_reference'
require_relative 'target_framework_reference'

module StructCore
	module Processor
		class TargetReferencesProcessor
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@system_ref_component = TargetSystemFrameworkReferenceComponent.new(@structure, @working_directory)
				@system_lib_ref_component = TargetSystemLibraryReferenceComponent.new(@structure, @working_directory)
				@local_ref_component = TargetLocalFrameworkReferenceComponent.new(@structure, @working_directory)
				@local_lib_ref_component = TargetLocalLibraryReferenceComponent.new(@structure, @working_directory)
				@subproj_ref_component = TargetFrameworkReferenceComponent.new(@structure, @working_directory)
			end

			def process(target, target_dsl = nil, dsl = nil)
				output = []

				output = process_xc_refs target if structure == :spec
				output = process_spec_refs target, target_dsl, dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil?

				output
			end

			# @param target [Xcodeproj::Project::Object::PBXNativeTarget]
			def process_xc_refs(target) end

			# @param target [StructCore::Specfile::Target]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_refs(target, target_dsl, dsl)
				framework_group = dsl.frameworks_group.groups.find { |group| group.display_name == '$local' }
				framework_group = dsl.frameworks_group.new_group '$local', nil, '<group>' if framework_group.nil?

				# The 'Embed Frameworks' phase is missing by default from the Xcodeproj template, so we have to add it.
				embed_phase = dsl.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
				embed_phase.name = 'Embed Frameworks'
				embed_phase.symbol_dst_subfolder_spec = :frameworks
				target_dsl.build_phases.insert(target_dsl.build_phases.count, embed_phase)

				target.references.each { |ref|
					@system_ref_component.process ref, target_dsl, dsl.frameworks_group if ref.is_a?(StructCore::Specfile::Target::SystemFrameworkReference)
					@system_lib_ref_component.process ref, target_dsl, dsl.frameworks_group if ref.is_a?(StructCore::Specfile::Target::SystemLibraryReference)
					@local_ref_component.process ref, target_dsl, framework_group, embed_phase if ref.is_a?(StructCore::Specfile::Target::LocalFrameworkReference)
					@local_lib_ref_component.process ref, target_dsl, framework_group if ref.is_a?(StructCore::Specfile::Target::LocalLibraryReference)
					@subproj_ref_component.process ref, target, target_dsl, framework_group if ref.is_a?(StructCore::Specfile::Target::FrameworkReference)
				}
			end
		end
	end
end