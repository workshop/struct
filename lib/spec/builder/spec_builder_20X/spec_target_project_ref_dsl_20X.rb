module StructCore
	class SpecTargetProjectRefDSL20X
		def initialize
			@reference = nil
		end

		attr_accessor :reference

		def framework(name = nil, settings = nil)
			unless name.is_a?(String) && !name.empty?
				@reference = nil
				return
			end

			target = (settings || {}).dup
			target['name'] = name

			# Convert any keys to hashes
			target = target.map { |k, v| [k.to_s, v] }.to_h

			@reference.settings['frameworks'] << target
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
	end
end