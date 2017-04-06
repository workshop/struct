module StructCore
	class SpecSchemeProfileConfigurationDSL20X
		attr_accessor :configuration

		def initialize
			@configuration = nil
		end

		def override(key = nil, value = nil)
			return if key.nil?
			@configuration[key] = value
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
	end
end