require_relative 'processor_component'
require_relative 'target'

module StructCore
	module Processor
		class TargetsComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				@target_component = TargetComponent.new(@structure, @working_directory)
				super
			end

			def process(project, dsl = nil)
				output = []

				output = process_xc_targets project if structure == :spec
				output = process_spec_targets project, dsl if structure == :xcodeproj && !dsl.nil?

				output
			end

			def process_xc_targets(project)
				project.targets.map { |target| @target_component.process target }.compact
			end

			def process_spec_targets(project, dsl)
				project.targets.each { |target| @target_component.process target, dsl }
			end
		end
	end
end