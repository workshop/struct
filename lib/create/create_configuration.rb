require_relative '../spec/spec_file'
require_relative '../spec/writer/spec_writer'
require 'paint'
require 'mustache'
require 'inquirer'

module StructCore
	module Create
		class Configuration
			PROFILE_NAMES = Dir[File.join(__dir__, '..', '..', 'res', 'config_profiles', '*.yml')].map { |name|
				File.basename(name).sub('_', ':').sub('.yml', '')
			}.freeze

			def self.run_interactive
				project_file = query_project_file
				type = query_configuration_types
				profiles = query_profiles

				configuration = StructCore::Specfile::Configuration.new(name, profiles, nil, type)
				run project_file, configuration
			end

			def self.query_project_file
				directory = Dir.pwd
				project_file = nil

				project_file = File.join(directory, 'project.yml') if File.exist? File.join(directory, 'project.yml')
				project_file = File.join(directory, 'project.json') if File.exist? File.join(directory, 'project.json')
				project_file = Ask.input 'Enter the project spec path' if project_file.nil?

				project_file = File.join(directory, project_file) unless Pathname.new(project_file).absolute?
				raise StandardError.new 'Unable to locate project file' unless File.exist? project_file

				project_file
			end

			def self.query_configuration_types
				name = Ask.input 'Enter a configuration name'
				raise StandardError.new 'Configuration name must be at least 1 character long' if name.nil? || name.empty?

				configuration_types = %w(debug release)
				if configuration_types.include? name
					type = nil
				else
					selected_type = Ask.list 'Please select this configuration\'s type', %w(Debug Release)
					type = configuration_types[selected_type]
				end

				type
			end

			def self.query_profiles
				profiles = Ask.checkbox('Please select one or many configuration profiles', PROFILE_NAMES).map.with_index { |selection, index|
					selection ? PROFILE_NAMES[index] : nil
				}.compact

				raise StandardError.new 'No platform or configuration profiles were specified' if profiles.nil? || profiles.empty?
				profiles
			end

			def self.run(project_file, configuration)
				unless !configuration.nil? && configuration.is_a?(StructCore::Specfile::Configuration)
					raise StandardError.new 'Invalid configuration object'
				end

				spec = StructCore::Specfile.parse project_file

				unless spec.configurations.find { |existing_config| existing_config.name == configuration.name }.nil?
					raise StandardError.new "A configuration with the name #{configuration.name} already exists in this spec"
				end

				StructCore::Specwriter.new.write_configuration configuration, spec.version, project_file
			end
		end
	end
end
