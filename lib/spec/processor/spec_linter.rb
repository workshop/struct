require_relative 'processor_component'
require_relative 'target_configurations_linter'

module StructCore
	module Processor
		class SpecLinterComponent
			include ProcessorComponent

			def initialize(structure, working_directory, target_configurations_component = nil)
				super(structure, working_directory)
				@target_configurations_component = target_configurations_component
				@target_configurations_component ||= TargetConfigurationsLinterComponent.new(@structure, @working_directory)
			end

			def process(project)
				return unless project.is_a?(StructCore::Specfile)
				@target_configurations_component.process project
			end
		end
	end
end