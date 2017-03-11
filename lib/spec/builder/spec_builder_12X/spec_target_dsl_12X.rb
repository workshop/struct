module StructCore
	class SpecConfigurationDSL12X
		def initialize
			@target = nil
		end

		attr_accessor :target

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