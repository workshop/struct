require_relative 'processor_component'

module StructCore
	module Processor
		class TargetSourceComponent
			include ProcessorComponent

			def process(source, target_dsl = nil, group_dsl = nil)
				output = nil

				output = process_xc_source source if structure == :spec
				output = process_spec_source source, target_dsl, group_dsl if structure == :xcodeproj && !target_dsl.nil? && !group_dsl.nil?

				output
			end

			# @param source [Xcodeproj::Project::Object::PBXFileReference]
			def process_xc_source(source)
				path = source.real_path.to_s.sub(@working_directory, '')
				path[0] = '' if path.start_with? '/'

				path
			end

			# @param source [String]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param group_dsl [Xcodeproj::Project::Object::PBXGroup]
			def process_spec_source(source, target_dsl, group_dsl)
				file = source.sub(@working_directory, '')
				file[0] = '' if file.start_with? '/'

				native_group = file.include?('/') ? create_group(group_dsl, File.dirname(file).split('/')) : group_dsl
				native_file = native_group.new_file File.basename(file)
				build_file = nil
				if file.end_with? '.swift', '.m', '.mm'
					target_dsl.source_build_phase.files_references << native_file
					build_file = target_dsl.add_file_references([native_file]).first
				elsif target_dsl.product_reference.path.end_with?('.framework') && file.end_with?('.h')
					header = target_dsl.headers_build_phase.add_file_reference native_file, true
					header.settings = { 'ATTRIBUTES' => %w(Public) }
				elsif file.end_with? '.entitlements'
					return
				elsif file.include? '.' # Files without an extension break Xcode compilation during resource phase
					target_dsl.add_resources [native_file]
				end

				build_file || native_file
			end

			def create_group(parent_group, components)
				return parent_group if components.first.nil?
				group = parent_group[components.first]
				unless group
					group = parent_group.new_group(components.first)
					group.source_tree = '<group>'
					group.path = components.first
				end
				create_group group, components.drop(1)
			end
		end
	end
end