module StructCore
	class SpecSchemeBuildTargetDSL20X
		attr_accessor :target

		def initialize
			@target = nil
		end

		def enable_archiving
			@target.archiving_enabled = true
		end

		def enable_running
			@target.running_enabled = true
		end

		def enable_profiling
			@target.profiling_enabled = true
		end

		def enable_testing
			@target.testing_enabled = true
		end

		def enable_analyzing
			@target.analyzing_enabled = true
		end

		def respond_to_missing?(_, _)
			true
		end

		def method_missing(_, *_)
			# Do nothing if a method is missing
		end
	end
end