require_relative '../spec/spec_file'
require_relative '../xcodeproj/xcodeproj_writer'
require 'paint'
require 'mustache'
require 'inquirer'

module StructCore
	module Create
		class Struct
			def self.run_interactive
				struct_name = Ask.input 'Enter a struct name'
				exit 0 if struct_name.nil? || struct_name.empty?

				struct_path = Ask.input 'Enter the destination path'
				if struct_path.nil? || struct_path.empty?
					puts Paint['Invalid destination path', :red]
					exit 0
				end

				if struct_path.start_with?('/', '\\')
					puts Paint['Destination path must be relative to current directory', :red]
					exit 0
				end

				run struct_name, struct_path
			end

			def self.run(struct_name, struct_path)
				struct_template = File.read File.join(__dir__, '..', '..', 'res', 'create_templates', 'struct.mustache')
				struct_destination = struct_path.end_with?('.swift') ? struct_path : File.join(struct_path, "#{struct_name}.swift")
				struct_directory = File.dirname struct_destination

				FileUtils.mkdir_p struct_directory
				FileUtils.rm_rf struct_destination
				File.write struct_destination, Mustache.render(struct_template, struct_name: struct_name)
			end
		end
	end
end