require_relative 'processor_component'
require_relative 'target_metadata'
require_relative 'target'
require_relative 'target_embeds'

module StructCore
	module Processor
		class TargetsComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@target_metadata_component = TargetMetadataComponent.new(@structure, @working_directory)
				@target_component = TargetComponent.new(@structure, @working_directory)
			end

			def process(project, dsl = nil)
				output = []

				output = process_xc_targets project if structure == :spec
				output = process_spec_targets project, dsl if structure == :xcodeproj && !dsl.nil?

				output
			end

			def process_xc_targets(project)
				project.targets.map { |target|
					target_dsl = @target_metadata_component.process target
					@target_component.process target, target_dsl
				}.compact
			end

			def process_spec_targets(project, dsl)
				embed_component = TargetEmbedsComponent.new(@structure, @working_directory, project)

				project.targets.map { |target|
					# Pre-create all target DSL objects before they're filled in, as this allows us to resolve target refs
					target_dsl = @target_metadata_component.process(target, dsl)
					next nil if target_dsl.nil?

					[target, target_dsl]
				}.compact.each { |data|
					target, target_dsl = data
					embed_component.register target, target_dsl
					@target_component.process target, target_dsl, dsl
				}

				embed_component.process dsl
			end
		end
	end
end