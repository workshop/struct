require_relative '../spec/spec_file'
require_relative '../xcodeproj/xcodeproj_writer'
require 'paint'
require 'mustache'
require 'inquirer'

module Xcodegen
	module Create
		class Class
			def self.run_interactive
				class_name = Ask.input 'Enter a class name'
				if class_name == nil || class_name.length == 0
					exit 0
				end

				class_path = Ask.input 'Enter the destination path'
				if class_path == nil || class_path.length == 0
					puts Paint['Invalid destination path', :red]
					exit 0
				end

				if class_path.start_with?('/') || class_path.start_with?('\\')
					puts Paint['Destination path must be relative to current directory', :red]
					exit 0
				end

				run class_name, class_path
			end

			def self.run(class_name, class_path)
				class_template = File.read File.join(__dir__, '..', '..', 'res', 'create_templates', 'class.mustache')
				class_destination = class_path.end_with?('.swift') ?
					class_path :
					File.join(class_path, "#{class_name}.swift")
				class_directory = File.dirname class_destination

				FileUtils.mkdir_p class_directory
				FileUtils.rm_rf class_destination
				File.write class_destination, Mustache.render(class_template, class_name: class_name)
			end
		end
	end
end