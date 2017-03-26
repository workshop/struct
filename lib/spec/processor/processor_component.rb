module StructCore
	module Processor
		module ProcessorComponent
			def initialize(structure, working_directory)
				@structure = structure
				@working_directory = working_directory
			end

			attr_accessor :structure
			attr_accessor :working_directory

			def process(*args) end
		end
	end
end