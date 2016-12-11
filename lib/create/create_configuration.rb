require_relative '../spec/spec_file'
require_relative '../spec/writer/spec_writer'
require 'paint'
require 'mustache'
require 'inquirer'

module Xcodegen
	module Create
		class Configuration

			PROFILE_NAMES = Dir[File.join(__dir__, '..', '..', 'res', 'config_profiles', '*.yml')].map { |name|
				File.basename(name).sub('_', ':').sub('.yml', '')
			}.freeze

			def self.run_interactive
				directory = Dir.pwd
				if File.exist? File.join(directory, 'project.yml')
					project_file = File.join(directory, 'project.yml')
				elsif File.exist? File.join(directory, 'project.json')
					project_file = File.join(directory, 'project.json')
				else
					project_file = Ask.input 'Enter the project spec path'
					unless Pathname.new(project_file).absolute?
						project_file = File.join(directory, project_file)
					end
				end

				raise StandardError.new 'Unable to locate project file' unless File.exist? project_file
				spec = Xcodegen::Specfile.parse(project_file)
				name = Ask.input 'Enter a configuration name'
				raise StandardError.new 'Configuration name must be at least 1 character long' unless name != nil && name.length > 0

				configuration_types = ['debug', 'release']
				if configuration_types.include? name
					type = nil
				else
					selected_type = Ask.list 'Please select this configuration\'s type', ['Debug', 'Release']
					type = configuration_types[selected_type]
				end

				profiles = Ask.checkbox('Please select one or many configuration profiles', PROFILE_NAMES)
					.map.with_index { |selection, index|
						selection ? PROFILE_NAMES[index] : nil
					}.compact

				unless profiles != nil && profiles.length > 0
					raise StandardError.new 'No platform or configuration profiles were specified'
				end

				configuration = Xcodegen::Specfile::Configuration.new(
					name,
					profiles,
					nil,
					type
				)

				run project_file, configuration
			end

			def self.run(project_file, configuration)
				unless configuration != nil && configuration.is_a?(Xcodegen::Specfile::Configuration)
					raise StandardError.new 'Invalid configuration object'
				end

				spec = Xcodegen::Specfile.parse project_file

				unless spec.configurations.find { |existing_config| existing_config.name == configuration.name } == nil
					raise StandardError.new "A configuration with the name #{configuration.name} already exists in this spec"
				end

				Xcodegen::Specwriter.new.write_configuration configuration, spec.version, project_file
			end
		end
	end
end
