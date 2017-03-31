require_relative 'processor_component'
require_relative 'configuration'

module StructCore
	module Processor
		class ConfigurationsComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@configuration_component = ConfigurationComponent.new @structure, @working_directory
			end

			def process(project, dsl = nil)
				output = nil
				output = process_xc_configurations project if structure == :spec
				output = process_spec_configurations project, dsl if structure == :xcodeproj && !dsl.nil?

				output
			end

			def process_xc_configurations(project)
				project.build_configurations.map { |config| @configuration_component.process config }
			end

			def process_spec_configurations(project, dsl)
				project.configurations.each { |config| @configuration_component.process config, dsl }
				dsl.build_configuration_list.default_configuration_name = project.configurations[0].name
			end
		end
	end
end