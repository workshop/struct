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
				spec = StructCore::Specfile.parse(project_file)

				valid_config_names = spec.configurations.map { |config|
					config.name
				}

				target_name = Ask.input 'Enter a target name'
				unless target_name != nil && target_name.length > 0
					raise StandardError.new 'Invalid target name'
				end

				type_key_idx = Ask.list 'Choose a target type', PRODUCT_TYPE.keys
				type = PRODUCT_TYPE[PRODUCT_TYPE.keys[type_key_idx]]
				type[0] = ''
				raw_type = type
				type = "com.apple.product-type.#{type}"

				sources = Ask.input 'Enter a sources directory, or blank for none'
				unless sources == nil || !Pathname.new(sources).absolute?
					raise StandardError.new 'Sources directory must be relative to project file'
				end

				i18n_resources = Ask.input 'Enter an i18n resources directory, or blank for none'
				unless i18n_resources == nil || !Pathname.new(i18n_resources).absolute?
					raise StandardError.new 'i18n resources directory must be relative to project file'
				end

				platform_idx = Ask.list 'Choose a platform, or Manual if you wish to select configuration profiles', [
					'iOS',
					'macOS',
					'Manual'
				]

				if platform_idx == 0
					platform = 'ios'
					profiles = [raw_type, 'platform:ios']
				elsif platform_idx == 1
					platform = 'mac'
					profiles = [raw_type, 'platform:mac']
				else
					platform = nil
					profiles = Ask.checkbox('Please select one or many configuration profiles', PROFILE_NAMES)
						.map.with_index { |selection, index|
							selection ? PROFILE_NAMES[index] : nil
						}.compact

					unless profiles != nil && profiles.length > 0
						raise StandardError.new 'No platform or configuration profiles were specified'
					end
				end

				configuration = {}
				configuration['PRODUCT_BUNDLE_IDENTIFIER'] = "com.example.#{target_name}"

				if platform == nil
					references = []
				elsif platform == 'ios'
					references = [Specfile::Target::SystemFrameworkReference.new('UIKit')]
				elsif platform == 'mac'
					references = [Specfile::Target::SystemFrameworkReference.new('AppKit')]
				end

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

			def self.run(project_file, target)
				unless target != nil && target.is_a?(StructCore::Specfile::Target)
					raise StandardError.new 'Invalid target object'
				end

				spec = StructCore::Specfile.parse project_file

				unless spec.targets.find { |existing_target| existing_target.name == target.name } == nil
					raise StandardError.new "A target with the name #{target.name} already exists in this spec"
				end

				spec.targets << target

				StructCore::Specwriter.new.write_target target, spec.version, project_file
			end
		end
	end
end