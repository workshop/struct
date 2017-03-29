require_relative 'processor_component'
require_relative 'target_configurations'
require_relative 'target_sources'

module StructCore
	module Processor
		class TargetComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@configurations_component = TargetConfigurationsComponent.new(@structure, @working_directory)
				@sources_component = TargetSourcesComponent.new(@structure, @working_directory)
			end

			def process(target, target_dsl = nil, dsl = nil)
				output = nil
				output = process_xc_target target, target_dsl if structure == :spec && !target_dsl.nil?
				output = process_spec_target target, target_dsl, dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil?

				output
			end

			# @param target [Xcodeproj::Project::PBXNativeTarget]
			# @param target_dsl [StructCore::Specfile::Target]
			def process_xc_target(target, target_dsl)
				target_dsl.configurations = @configurations_component.process target, target_dsl
				target_dsl.source_dir = @sources_component.process target, target_dsl
				target_dsl
			end

			# @param target [StructCore::Specfile::Target]
			# @param target_dsl [Xcodeproj::Project::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_target(target, target_dsl, dsl)
				@configurations_component.process target, target_dsl, dsl
				@sources_component.process target, target_dsl, dsl
			end
		end
	end
end