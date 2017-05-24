require_relative 'processor_component'
require_relative 'configurations'
require_relative 'targets'
require_relative 'variants'
require_relative 'schemes'
require_relative 'target_cross_platform'
require_relative '../../cocoapods/pod_assistant'
require 'paint'

module StructCore
	module Processor
		class ProjectComponent
			include ProcessorComponent

			def initialize(structure, working_directory, configurations_component = nil, targets_component = nil, variants_component = nil, schemes_component = nil, xplat_component = nil)
				super(structure, working_directory)
				@configurations_component = configurations_component
				@targets_component = targets_component
				@variants_component = variants_component
				@schemes_component = schemes_component
				@xplat_component = xplat_component

				@configurations_component ||= ConfigurationsComponent.new @structure, @working_directory
				@targets_component ||= TargetsComponent.new @structure, @working_directory
				@variants_component ||= VariantsComponent.new @structure, @working_directory
				@schemes_component ||= SchemesComponent.new @structure, @working_directory
				@xplat_component ||= TargetCrossPlatformComponent.new @structure, @working_directory
			end

			def process(project, selected_variants = [])
				output = []
				output = process_xc_project project if structure == :spec
				output = process_spec_project project, selected_variants if structure == :xcodeproj

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
						version = LATEST_SPEC_VERSION
					end
				end

				dsl = StructCore::Specfile.new(version, [], [], [], working_directory, false)
				dsl.configurations = @configurations_component.process project
				dsl.targets = @targets_component.process project

				[ProcessorOutput.new(dsl, File.join(working_directory, 'project.yml'))]
			end

			def process_spec_project(project, selected_variants)
				version = project.version

				projects = []
				projects = [['project', project]] if project.variants.empty?
				projects = @variants_component.process(project, selected_variants) unless project.variants.empty?
				projects.each { |_, p| @xplat_component.process p }

				schemes = []

				outputs = projects.map { |proj_data|
					name, proj = proj_data
					puts Paint["Processing project '#{name}'..."]

					StructCore::PodAssistant.apply_pod_configuration proj, working_directory

					dsl = Xcodeproj::Project.new File.join(working_directory, "#{name}.xcodeproj")
					dsl.root_object.attributes['Struct.Version'] = version.to_s
					dsl.build_configurations.clear
					@configurations_component.process proj, dsl
					@targets_component.process proj, dsl
					dsl.predictabilize_uuids

					schemes.unshift(*@schemes_component.process(project, dsl))
					ProcessorOutput.new(dsl, File.join(working_directory, "#{name}.xcodeproj"))
				}

				outputs.push(*schemes.map { |data|
					scheme, scheme_name, proj_output_path = data
					ProcessorOutput.new(scheme, File.join(proj_output_path, 'xcshareddata', 'xcschemes', "#{scheme_name}.xcscheme"), project: proj_output_path, name: scheme_name)
				})

				outputs
			end

			private :process_xc_project
			private :process_spec_project
		end
	end
end