require_relative 'processor_component'
require_relative 'configurations'
require_relative 'targets'
require_relative 'variants'
require_relative '../../cocoapods/pod_assistant'
require 'paint'

module StructCore
	module Processor
		class ProjectComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@configurations_component = ConfigurationsComponent.new @structure, @working_directory
				@targets_component = TargetsComponent.new @structure, @working_directory
				@variants_component = VariantsComponent.new @structure, @working_directory
			end

			def process(project)
				output = []
				output = process_xc_project project if structure == :spec
				output = process_spec_project project if structure == :xcodeproj

				output
			end

			def process_xc_project(project)
				version = project.root_object.attributes['Struct.Version']

				if version.nil?
					version = LATEST_SPEC_VERSION
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
				version = project.version

				projects = []
				projects = [['project', project]] if project.variants.empty?
				projects = @variants_component.process(project) unless project.variants.empty?

				projects.map { |proj_data|
					name, proj = proj_data
					puts Paint["Processing project '#{name}'..."]

					StructCore::PodAssistant.apply_pod_configuration proj, working_directory

					dsl = Xcodeproj::Project.new File.join(working_directory, "#{name}.xcodeproj")
					dsl.root_object.attributes['Struct.Version'] = version.to_s
					dsl.build_configurations.clear
					@configurations_component.process proj, dsl
					@targets_component.process proj, dsl

					ProcessorOutput.new(dsl, File.join(working_directory, "#{name}.xcodeproj"))
				}
			end
		end
	end
end