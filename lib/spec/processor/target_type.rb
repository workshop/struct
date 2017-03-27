require_relative 'processor_component'

module StructCore
	module Processor
		class TargetTypeComponent
			include ProcessorComponent

			def process(target)
				output = nil
				output = process_xc_target target if structure == :spec
				output = process_spec_target target if structure == :xcodeproj

				output
			end

			# @param target [Xcodeproj::Project::PBXNativeTarget]
			def process_xc_target(target)
				target.product_type.sub 'com.apple.product-type.', ':'
			end

			# @param target [StructCore::Specfile::Target]
			def process_spec_target(target)
				XC_PRODUCT_TYPE_UTI_INV[target.type]
			end
		end
	end
end