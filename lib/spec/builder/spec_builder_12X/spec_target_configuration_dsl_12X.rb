module StructCore
	class SpecTargetConfigurationDSL12X
		def initialize
			@configuration = nil
		end

		attr_accessor :configuration

		def profile(profile)
			@configuration.profiles << profile
		end

		def override(key, value)
			@configuration.settings[key] = value
		end

		def source(source)
			@configuration.source = source
		end

		def respond_to_missing?(_, _)
			true
		end

		# rubocop:disable Style/MethodMissing
		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
		# rubocop:enable Style/MethodMissing
	end
end