require_relative '../spec_file'

module StructCore
	class SpecScriptsProcessor
		class HookScriptContext
			def initialize(*args)
				@args = args
			end

			def run(&block)
				block.call(*@args)
			end
		end

		# @param spec [StructCore::Specfile]
		def pre_generate(spec)
			return unless spec.is_a?(StructCore::Specfile)
			return if spec.pre_generate_script.nil?
			execute_script_file spec.pre_generate_script.script_path, spec if spec.pre_generate_script.is_a?(StructCore::Specfile::HookScript)
			execute_script_block spec.pre_generate_script.block, spec if spec.pre_generate_script.is_a?(StructCore::Specfile::HookBlockScript)
		end

		# @param spec [StructCore::Specfile]
		def post_generate(spec, xcodeproj)
			return unless spec.is_a?(StructCore::Specfile) && xcodeproj.is_a?(Xcodeproj::Project)
			return if spec.post_generate_script.nil?
			execute_script_file spec.post_generate_script.script_path, spec, xcodeproj if spec.post_generate_script.is_a?(StructCore::Specfile::HookScript)
			execute_script_block spec.post_generate_script.block, spec, xcodeproj if spec.post_generate_script.is_a?(StructCore::Specfile::HookBlockScript)
		end

		def execute_script_file(script_path, *args)
			ctx = HookScriptContext.new(*args)
			ctx.instance_eval File.read(script_path)
		end

		def execute_script_block(block, *args)
			instance_exec(*args, &block)
		end

		private :execute_script_file
		private :execute_script_block
	end
end