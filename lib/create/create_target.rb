require_relative '../spec/spec_file'
require_relative '../spec/writer/spec_writer'
require 'paint'
require 'mustache'
require 'inquirer'

module StructCore
	module Create
		class Target
			PRODUCT_TYPE = {
				'Application' => ':application',
				'Framework' => ':framework',
				'Dynamic library' => ':library.dynamic',
				'Static library' => ':library.static',
				'Bundle' => ':bundle',
				'Unit test' => ':bundle.unit-test',
				'UI test' => ':bundle.ui-testing',
				'App extension' => ':app-extension',
				'WatchOS app' => ':application.watchapp',
				'WatchOS2 app' => ':application.watchapp2',
				'Watch extension' => ':watchkit-extension',
				'Watch2 extension' => ':watchkit2-extension',
				'TV extension' => ':tv-app-extension',
				'Messages application' => ':application.messages',
				'Messages extension' => ':app-extension.messages',
				'Messages sticker pack' => ':app-extension.messages-sticker-pack',
				'XPC service' => ':xpc-service'
			}.freeze

			PROFILE_NAMES = Dir[File.join(__dir__, '..', '..', 'res', 'target_config_profiles', '*.yml')].map { |name|
				File.basename(name).sub('_', ':').sub('.yml', '')
			}.freeze

			def self.run_interactive
				project_file = query_project_file
				spec = StructCore::Specfile.parse(project_file)

				valid_config_names = spec.configurations.map(&:name)
				target_name = query_target_name
				type, raw_type = query_project_type
				sources = query_sources_dir
				i18n_resources = query_i18n_dir

				platform, profiles = query_platform raw_type

				configuration = {}
				configuration['PRODUCT_BUNDLE_IDENTIFIER'] = "com.example.#{target_name}"

				references = []
				references = [Specfile::Target::SystemFrameworkReference.new('UIKit')] if 'ios' == platform
				references = [Specfile::Target::SystemFrameworkReference.new('AppKit')] if 'mac' == platform

				configurations = valid_config_names.map { |name|
					Specfile::Target::Configuration.new(name, configuration, profiles)
				}

				target = StructCore::Specfile::Target.new(
					target_name,
					type,
					sources,
					configurations,
					references,
					[],
					i18n_resources,
					[]
				)

				run project_file, target
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

			def self.query_target_name
				target_name = Ask.input 'Enter a target name'
				raise StandardError.new 'Invalid target name' if target_name.nil? || target_name.empty?

				target_name
			end

			def self.query_project_type
				type_key_idx = Ask.list 'Choose a target type', PRODUCT_TYPE.keys
				type = PRODUCT_TYPE[PRODUCT_TYPE.keys[type_key_idx]]
				type[0] = ''

				["com.apple.product-type.#{type}", type]
			end

			def self.query_sources_dir
				dir = Ask.input 'Enter a sources directory, or blank for none'
				unless sources.nil? || !Pathname.new(sources).absolute?
					raise StandardError.new 'Sources directory must be relative to project file'
				end

				dir
			end

			def self.query_i18n_dir
				i18n_resources = Ask.input 'Enter an i18n resources directory, or blank for none'
				unless i18n_resources.nil? || !Pathname.new(i18n_resources).absolute?
					raise StandardError.new 'i18n resources directory must be relative to project file'
				end

				i18n_resources
			end

			def self.query_platform(raw_type)
				platform_idx = Ask.list 'Choose a platform, or Manual if you wish to select configuration profiles', %w(iOS macOS Manual)

				if platform_idx.is_zero?
					platform = 'ios'
					profiles = [raw_type, 'platform:ios']
				elsif platform_idx == 1
					platform = 'mac'
					profiles = [raw_type, 'platform:mac']
				else
					platform = nil
					profiles = Ask.checkbox('Please select one or many configuration profiles', PROFILE_NAMES).map.with_index { |selection, index|
						selection ? PROFILE_NAMES[index] : nil
					}.compact

					raise StandardError.new 'No platform or configuration profiles were specified' if profiles.nil? || profiles.empty?
				end

				[platform, profiles]
			end

			def self.run(project_file, target)
				unless !target.nil? && target.is_a?(StructCore::Specfile::Target)
					raise StandardError.new 'Invalid target object'
				end

				spec = StructCore::Specfile.parse project_file

				unless spec.targets.find { |existing_target| existing_target.name == target.name }.nil?
					raise StandardError.new "A target with the name #{target.name} already exists in this spec"
				end

				spec.targets << target

				StructCore::Specwriter.new.write_target target, spec.version, project_file
			end
		end
	end
end