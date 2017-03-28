require_relative 'processor_component'
require_relative 'target_configuration'

module StructCore
	module Processor
		class TargetConfigurationsComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@configuration_component = TargetConfigurationComponent.new @structure, @working_directory
			end

			def process(target, target_dsl = nil, dsl = nil)
				output = []

				output = process_xc_target target, target_dsl if structure == :spec && !target_dsl.nil?
				output = process_spec_target target, target_dsl, dsl if structure == :xcodeproj && !dsl.nil? && !target_dsl.nil?

				output
			end

			# @param target [Xcodeproj::Project::PBXNativeTarget]
			def process_xc_target(target, target_dsl)
				target.build_configurations.map { |config| @configuration_component.process config, target_dsl, target }
			end

			# @param target [StructCore::Specfile::Target]
			# @param target_dsl [Xcodeproj::Project::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_target(target, target_dsl, dsl)
				target.configurations.each { |config| @configuration_component.process config, target_dsl, dsl }
			end
		end
	end
end