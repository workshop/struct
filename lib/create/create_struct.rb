require_relative '../spec/spec_file'
require_relative '../xcodeproj/xcodeproj_writer'
require 'paint'
require 'mustache'
require 'inquirer'

module Xcodegen
	module Create
		class Struct
			def self.run_interactive
				struct_name = Ask.input 'Enter a struct name'
				if struct_name == nil || struct_name.length == 0
					exit 0
				end

				struct_path = Ask.input 'Enter the destination path'
				if struct_path == nil || struct_path.length == 0
					puts Paint['Invalid destination path', :red]
					exit 0
				end

				if struct_path.start_with?('/') || struct_path.start_with?('\\')
					puts Paint['Destination path must be relative to current directory', :red]
					exit 0
				end

				run struct_name, struct_path
			end

			def self.run(struct_name, struct_path)
				struct_template = File.read File.join(__dir__, '..', '..', 'res', 'create_templates', 'struct.mustache')
				struct_destination = struct_path.end_with?('.swift') ?
					struct_path :
					File.join(struct_path, "#{struct_name}.swift")
				struct_directory = File.dirname struct_destination

				FileUtils.mkdir_p struct_directory
				FileUtils.rm_rf struct_destination
				File.write struct_destination, Mustache.render(struct_template, struct_name: struct_name)
			end
		end
	end
end