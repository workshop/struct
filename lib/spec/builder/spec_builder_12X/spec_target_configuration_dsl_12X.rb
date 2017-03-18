module StructCore
	class SpecTargetConfigurationDSL12X
		def initialize
			@configuration = nil
		end

		attr_accessor :configuration

		def profile(profile = nil)
			return unless profile.is_a?(String) && !profile.empty?
			@configuration.profiles << profile
		end

		def override(key = nil, value = nil)
			return unless key.is_a?(String) && !key.empty? && value.is_a?(String)
			@configuration.settings[key] = value
		end

		def source(source = nil)
			return unless source.is_a?(String) && !source.empty?
			@configuration.source = source
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
	end
end