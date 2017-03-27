require_relative 'processor_component'

module StructCore
	module Processor
		class TargetComponent
			include ProcessorComponent

			def process(target, dsl = nil)
				output = nil
				output = process_xc_target target if structure == :spec
				output = process_spec_target target, dsl if structure == :xcodeproj

				output
			end

			def process_xc_target(target) end

			def process_spec_target(target, dsl) end
		end
	end
end