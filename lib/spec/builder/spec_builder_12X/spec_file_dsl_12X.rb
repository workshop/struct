require_relative 'spec_configuration_dsl_12X'
require_relative 'spec_target_dsl_12X'

module StructCore
	class SpecFileDSL12X
		def initialize
			@spec_file = nil
			@project_base_dir = nil
		end

		def supports_version(version)
			version.major == 1 && version.minor == 2
		end

		attr_accessor :spec_file
		attr_accessor :project_base_dir

		def configuration(name, &block)
			dsl = StructCore::SpecConfigurationDSL12X.new
			dsl.configuration = StructCore::Specfile::Configuration.new(name, [], {}, nil, nil)
			dsl.instance_eval(&block)

			@spec_file.configurations << dsl.configuration
		end

		def target(name, &block)
			dsl = StructCore::SpecTargetDSL12X.new
			dsl.project_configurations = @spec_file.configurations
			dsl.project_base_dir = @project_base_dir
			dsl.target = StructCore::Specfile::Target.new(name, nil, [], [], [], [], [], [], [], [])
			dsl.instance_eval(&block)

			@spec_file.targets << dsl.target
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