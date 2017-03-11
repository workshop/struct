module StructCore
	class SpecConfigurationDSL12X
		def initialize
			@configuration = nil
		end

		attr_accessor :configuration

		def profile(profile)
			@configuration.profiles << profile
		end

		def override(key, value)
			@configuration.overrides[key] = value
		end

		def type(type)
			@configuration.type = type
		end

		def source(source)
			@configuration.source = source
		end

		def method_missing(name, *values)
			# Do nothing if a method is missing
		end
	end
end