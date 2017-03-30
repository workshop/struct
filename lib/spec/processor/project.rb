require_relative 'processor_component'
require_relative 'configurations'
require_relative 'targets'
require_relative '../../cocoapods/pod_assistant'

module StructCore
	module Processor
		class ProjectComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@configurations_component = ConfigurationsComponent.new @structure, @working_directory
				@targets_component = TargetsComponent.new @structure, @working_directory
			end

			def process(project)
				proj = deep_clone project

				output = []
				output = process_xc_project proj if structure == :spec
				output = process_spec_project proj if structure == :xcodeproj

				output
			end

			def process_xc_project(project)
				version = project.root_object.attributes['Struct.Version']

				if version.nil?
					version = SPEC_VERSION_130
				else
					begin
						version = Semantic::Version.new version
					rescue
						return []
					end
				end

				dsl = StructCore::Specfile.new(version, [], [], [], working_directory, false)
				dsl.configurations = @configurations_component.process project
				dsl.targets = @targets_component.process project

				[ProcessorOutput.new(dsl, File.join(working_directory, 'project.yml'))]
			end

			def process_spec_project(project)
				StructCore::PodAssistant.apply_pod_configuration project, @working_directory
				version = project.version

				dsl = Xcodeproj::Project.new File.join(working_directory, 'project.xcodeproj')
				dsl.root_object.attributes['Struct.Version'] = version.to_s
				dsl.build_configurations.clear
				@configurations_component.process project, dsl
				@targets_component.process project, dsl

				[ProcessorOutput.new(dsl, File.join(working_directory, 'project.xcodeproj'))]
			end
		end
	end
end