require_relative 'processor_component'
require_relative 'target_type'
require_relative 'target_platform'

module StructCore
	module Processor
		class TargetMetadataComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@type_component = TargetTypeComponent.new(@structure, @working_directory)
			end

			def process(target, dsl = nil)
				output = nil
				output = process_xc_target target if structure == :spec
				output = process_spec_target target, dsl if structure == :xcodeproj

				output
			end

			# @param target [Xcodeproj::Project::PBXNativeTarget]
			def process_xc_target(target)
				StructCore::Specfile::Target.new(
					target.name,
					@type_component.process(target),
					[],
					[],
					[],
					[],
					[],
					[],
					[],
					[]
				)
			end

			# @param target [StructCore::Specfile::Target]
			# @param dsl [Xcodeproj::Project]
			def process_spec_target(target, dsl)
				product_type = @type_component.process(target)

				# Target
				native_target = dsl.new(Xcodeproj::Project::Object::PBXNativeTarget)
				dsl.targets << native_target
				native_target.name = target.name
				native_target.product_name = target.name
				native_target.product_type = product_type
				native_target.build_configuration_list = dsl.new(Xcodeproj::Project::Object::XCConfigurationList)
				native_target.build_configuration_list.default_configuration_is_visible = '0'
				native_target.build_configuration_list.default_configuration_name = 'Release'

				# Product
				prefix = ''
				prefix = 'lib' if product_type == :static_library
				extension = StructCore::XC_PRODUCT_UTI_EXTENSIONS[product_type]
				product = Xcodeproj::Project::Object::FileReferencesFactory.new_reference(dsl.products_group, "#{prefix}#{target.name}.#{extension}", :built_products)
				product.include_in_index = '0'
				product.set_explicit_file_type
				native_target.product_reference = product

				# Build phases
				native_target.build_phases << dsl.new(Xcodeproj::Project::Object::PBXSourcesBuildPhase)
				native_target.build_phases << dsl.new(Xcodeproj::Project::Object::PBXFrameworksBuildPhase)

				native_target
			end
		end
	end
end