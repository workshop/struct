module StructCore
	class SpecConfigurationDSL12X
		def initialize
			@target = nil
		end

		attr_accessor :target

		def method_missing(name, *values)
			# Do nothing if a method is missing
		end
	end
end