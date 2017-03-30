require_relative '../builder/spec_builder'
require_relative '../writer/spec_writer'
require_relative '../spec_file'
require_relative 'project'
require_relative 'configurations'
require 'Xcodeproj'
require 'awesome_print'
require 'paint'

module StructCore
	class SpecProcessor
		def initialize(project_file, dry_run = false)
			return if project_file.to_s.empty?
			@full_project_path, target_structure = resolve_project_data project_file
			@dry_run = dry_run
			@project_component = StructCore::Processor::ProjectComponent.new(target_structure, File.dirname(@full_project_path))
		end

		def process
			source_dsl = process_source_dsl @full_project_path

			outputs = @project_component.process source_dsl
			return if outputs.empty?

			puts "\n" unless @dry_run

			outputs.each { |output|
				if @dry_run
					ap output.dsl if output.dsl.is_a?(Xcodeproj::Project)
					ap output.dsl, raw: true if output.dsl.is_a?(StructCore::Specfile)
				else
					StructCore::Specwriter.new.write_spec output.dsl, output.path unless output.path.end_with? '.xcodeproj'
					output.dsl.save output.path if output.path.end_with? '.xcodeproj'
					puts Paint["Saved '#{output.path}'"]
				end
			}
		end

		def resolve_project_data(project_file)
			full_project_path = project_file.to_s
			full_project_path = File.join(Dir.pwd, full_project_path) unless Pathname.new(full_project_path).absolute?

			if full_project_path.end_with? '.xcodeproj'
				target_structure = :spec
			elsif full_project_path.end_with? '.yaml'
				target_structure = :xcodeproj
			elsif full_project_path.end_with? '.yml'
				target_structure = :xcodeproj
			elsif full_project_path.end_with? '.json'
				target_structure = :xcodeproj
			elsif File.basename(full_project_path) == 'Specfile'
				target_structure = :xcodeproj
			else
				raise StandardError.new "Unrecognised project format: #{File.basename(full_project_path)}"
			end

			[full_project_path, target_structure]
		end

		def process_source_dsl(full_project_path)
			# TODO: Replace with Spec & DSL processor
			source_dsl = nil
			source_dsl = StructCore::Specfile.parse full_project_path if full_project_path.end_with?('.yml')
			source_dsl = StructCore::Specfile.parse full_project_path if full_project_path.end_with?('.yaml')
			source_dsl = StructCore::Specfile.parse full_project_path if full_project_path.end_with?('.json')
			source_dsl = StructCore::SpecBuilder.build full_project_path if full_project_path.end_with?('Specfile')
			source_dsl = Xcodeproj::Project.open full_project_path if full_project_path.end_with?('.xcodeproj')

			raise StandardError.new "Unrecognised project format: #{File.basename(full_project_path)}" if source_dsl.nil?

			source_dsl
		end

		private :resolve_project_data
		private :process_source_dsl
	end
end