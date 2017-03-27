require_relative 'processor_component'

module StructCore
	module Processor
		class TargetComponent
			include ProcessorComponent

			def process(target, target_dsl = nil, dsl = nil)
				output = nil
				output = process_xc_target target, target_dsl if structure == :spec && !target_dsl.nil?
				output = process_spec_target target, target_dsl, dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil?

				output
			end

			def process_xc_target(target, target_dsl) end

			def process_spec_target(target, target_dsl, dsl) end
		end
	end
end