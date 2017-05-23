require_relative 'processor_component'

module StructCore
	module Processor
		class TargetTargetReferenceComponent
			include ProcessorComponent

			def process(reference, target_dsl = nil, dsl = nil, group_dsl = nil, embed_dsl = nil)
				output = nil

				output = process_xc_reference reference if structure == :spec
				output = process_spec_reference reference, target_dsl, dsl, group_dsl, embed_dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil? && !group_dsl.nil? && !embed_dsl.nil?

				output
			end

			# @param reference [Xcodeproj::Project::Object::PBXNativeTarget]
			def process_xc_reference(reference)
				StructCore::Specfile::Target::TargetReference.new reference.name
			end

			# @param reference [StructCore::Specfile::Target::TargetReference]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_reference(reference, target_dsl, dsl, group_dsl, embed_dsl)
				other_target = dsl.targets.find { |t| t.name == reference.target_name }
				return nil if other_target.nil?

				target_dsl.add_dependency other_target
				return unless other_target.product_type == 'com.apple.product-type.framework'

				framework = group_dsl.new_file other_target.product_reference.path, 'BUILT_PRODUCTS_DIR'

				# Link
				target_dsl.frameworks_build_phase.add_file_reference framework

				# Embed
				settings = reference.settings || {}
				return unless settings.key?('copy') && settings['copy'] == true

				attributes = ['RemoveHeadersOnCopy']
				attributes.push 'CodeSignOnCopy' if settings.key?('codeSignOnCopy') && settings['codeSignOnCopy'] == true

				(embed_dsl.add_file_reference framework).settings = { 'ATTRIBUTES' => attributes }
			end
		end
	end
end