require_relative 'processor_component'

module StructCore
	module Processor
		class TargetResourceComponent
			include ProcessorComponent

			def process(resource, target_dsl = nil, group_dsl = nil)
				output = nil

				output = process_xc_resource resource if structure == :spec
				output = process_spec_resource resource, target_dsl, group_dsl if structure == :xcodeproj && !target_dsl.nil? && !group_dsl.nil?

				output
			end

			# @param resource [Xcodeproj::Project::Object::PBXFileReference]
			def process_xc_resource(resource)
				path = resource.real_path.to_s.sub(@working_directory, '')
				path[0] = '' if path.start_with? '/'

				path = path.split(/\/[A-Za-z]*\.lproj/).first

				path
			end

			# @param resource [String]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param group_dsl [Xcodeproj::Project::Object::PBXGroup]
			def process_spec_resource(resource, target_dsl, group_dsl)
				native_file = group_dsl.new_file(resource, '<group>')
				target_dsl.add_resources [native_file]
			end
		end
	end
end