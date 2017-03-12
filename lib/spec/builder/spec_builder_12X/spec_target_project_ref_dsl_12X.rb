module StructCore
	class SpecTargetProjectRefDSL12X
		def initialize
			@reference = nil
		end

		attr_accessor :reference

		def framework(name, settings)
			target = settings.dup
			target['name'] = name

			@reference.settings['frameworks'] << target
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