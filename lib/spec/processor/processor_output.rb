module StructCore
	module Processor
		class ProcessorOutput
			def initialize(dsl, path)
				@dsl = dsl
				@path = path
			end

			attr_accessor :dsl
			attr_accessor :path
		end
	end
end