require_relative 'processor_component'
require_relative 'target_script'

module StructCore
	module Processor
		class TargetScriptsComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@script_component = TargetScriptComponent.new(@structure, @working_directory)
			end

			def process(target, target_dsl = nil, dsl = nil)
				output = []

				output = process_xc_scripts target, target_dsl if structure == :spec && !target_dsl.nil?
				output = process_spec_scripts target, target_dsl, dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil?

				output
			end

			# @param target [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param target_dsl [StructCore::Specfile::Target]
			def process_xc_scripts(target, target_dsl) end

			# @param target [StructCore::Specfile::Target]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_scripts(target, target_dsl, dsl)
				target.prebuild_run_scripts.each { |script| @script_component.process script, target_dsl, dsl, :prebuild }
				target.postbuild_run_scripts.each { |script| @script_component.process script, target_dsl, dsl, :postbuild }
			end
		end
	end
end