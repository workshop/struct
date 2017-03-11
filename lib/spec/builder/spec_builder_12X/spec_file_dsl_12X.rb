module StructCore
	class SpecFileDSL12X
		def initialize
			@spec_file = nil
		end

		def supports_version(version)
			version.major == 1 && version.minor == 2
		end

		attr_accessor :spec_file
	end
end