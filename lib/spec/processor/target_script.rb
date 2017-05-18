require_relative 'processor_component'

module StructCore
	module Processor
		class TargetScriptComponent
			include ProcessorComponent

			def process(script, target_dsl = nil, dsl = nil, script_type = nil)
				output = nil

				output = process_xc_script script if structure == :spec
				output = process_spec_script script, target_dsl, dsl, script_type if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil? && !script_type.nil?

				output
			end

			# @param script [Xcodeproj::Project::Object::PBXFileReference]
			def process_xc_script(script) end

			# @param script [String]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			# @param script_type [Symbol]
			def process_spec_script(script, target_dsl, dsl, script_type)
				script_name = File.basename(script.script_path)
				script_path = script.script_path
				script_path = File.join(@working_directory, script_path) unless Pathname.new(script_path).absolute?
				script = File.read(script_path)

				script_phase = dsl.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
				script_phase.name = script_name
				script_phase.shell_script = script

				target_dsl.build_phases.unshift script_phase if script_type == :prebuild
				target_dsl.build_phases << script_phase if script_type == :postbuild
			end
		end
	end
end