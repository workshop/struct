module StructCore
	class SpecSchemeTestEnvironmentDSL30X
		attr_accessor :environment

		def initialize
			@environment = nil
		end

		def override(key = nil, value = nil)
			return if key.nil?
			@environment[key] = value
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
	end
end