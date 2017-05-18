module StructCore
	module Processor
		class ProcessorOutput
			def initialize(dsl, path, options = {})
				@dsl = dsl
				@path = path
				@options = options || {}
			end

			attr_accessor :dsl
			attr_accessor :path
			attr_accessor :options
		end
	end
end