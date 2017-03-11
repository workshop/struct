require_relative 'spec_configuration_dsl_12X'

module StructCore
	class SpecFileDSL12X
		def initialize
			@spec_file = nil
		end

		def supports_version(version)
			version.major == 1 && version.minor == 2
		end

		attr_accessor :spec_file

		def configuration(name, &block)
			dsl = StructCore::SpecConfigurationDSL12X.new
			dsl.configuration = StructCore::Specfile::Configuration.new(name, [], {}, nil, nil)
			dsl.instance_eval(&block)

			@spec_file.configurations << dsl.configuration
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