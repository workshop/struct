require_relative 'processor_component'
require_relative 'configurations'
require_relative 'processor_output'
require_relative '../spec_file'
require_relative '../../utils/defines'
require 'xcodeproj'
require 'semantic'

module StructCore
	module Processor
		class ProjectComponent
			include ProcessorComponent

			def process(project)
				@configurations_component = ConfigurationsComponent.new @structure, @working_directory

				output = []
				output = process_xc_project project if structure == :spec
				output = process_spec_project project if structure == :xcodeproj

				output
			end

			def process_xc_project(project)
				version = project.root_object.metadata['Struct.Version']

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

				[ProcessorOutput.new(dsl, File.join(working_directory, 'project.yml'))]
			end

			def process_spec_project(project)
				version = project.version

				dsl = Xcodeproj::Project.new File.join(working_directory, 'project.xcodeproj')
				dsl.root_object.attributes['Struct.Version'] = version.to_s
				dsl.build_configurations.clear
				@configurations_component.process project, dsl

				[ProcessorOutput.new(dsl, File.join(working_directory, 'project.xcodeproj'))]
			end
		end
	end
end