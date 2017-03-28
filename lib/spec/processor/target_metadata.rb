require_relative 'processor_component'
require_relative 'target_type'
require_relative 'target_platform'

module StructCore
	module Processor
		class TargetMetadataComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@type_component = TargetTypeComponent.new(@structure, @working_directory)
				@platform_component = TargetPlatformComponent.new(@structure, @working_directory)
			end

			def process(target, dsl = nil)
				output = nil
				output = process_xc_target target if structure == :spec
				output = process_spec_target target, dsl if structure == :xcodeproj

				output
			end

			# @param target [Xcodeproj::Project::PBXNativeTarget]
			def process_xc_target(target)
				StructCore::Specfile::Target.new(
					target.name,
					@type_component.process(target),
					[],
					[],
					[],
					[],
					[],
					[],
					[],
					[]
				)
			end

			# @param target [StructCore::Specfile::Target]
			# @param dsl [Xcodeproj::Project]
			def process_spec_target(target, dsl)
				target = dsl.new_target(
					@type_component.process(target),
					target.name,
					@platform_component.process(target),
					nil,
					nil,
					:swift
				)

				target.build_configurations.clear
				target
			end
		end
	end
end