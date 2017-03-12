require 'slop'
require 'version'
require 'paint'
require 'awesome_print'
require 'inquirer'
require_relative '../refresher/refresher'
require_relative '../watch/watcher'
require_relative '../spec/spec_file'
require_relative '../xcodeproj/xcodeproj_writer'
require_relative '../create/create_class'
require_relative '../create/create_struct'
require_relative '../create/create_target'
require_relative '../create/create_configuration'
require_relative '../spec/builder/spec_builder'
require_relative '../migrator/migrator'

module StructCore
	class CLI
		def self.quit(code)
			StructCore::Refresher.run
			exit code
		end

		def self.run
			opts = Slop.parse do |o|
				o.on '--parse', 'parses a spec file and prints the output' do
					return do_parse o
				end
				o.on '-w', '--watch', 'watches your source dirs for changes and generates an xcode project' do
					return do_watch o
				end
				o.on '-g', '--generate', 'generates an xcode project' do
					return do_generate o
				end
				o.on '-c', '--create', 'starts the resource creation wizard for creating files, targets, etc.' do
					return do_create o
				end
				o.on '-m', '--migrate', 'migrates an Xcode project and its files to a specfile (beta)' do
					return do_migrate o
				end
				o.on '-v', '--version', 'print the version' do
					puts StructCore::VERSION
					quit(0)
				end
			end

			puts opts
			quit(0)
		end

		private_class_method def self.do_parse(_)
			directory = Dir.pwd

			project_file = nil
			project_file = File.join(directory, 'project.yml') if File.exist? File.join(directory, 'project.yml')
			project_file = File.join(directory, 'project.json') if File.exist? File.join(directory, 'project.json')
			project_file = File.join(directory, 'Specfile') if File.exist? File.join(directory, 'Specfile')

			if project_file.nil?
				puts Paint['Could not find project.yml or project.json in the current directory', :red]
				quit(-1)
			end

			begin
				spec = nil
				spec = StructCore::Specfile.parse project_file unless project_file.end_with?('Specfile')
				spec = StructCore::SpecBuilder.build project_file if project_file.end_with?('Specfile')
			rescue StandardError => err
				puts Paint[err, :red]
				quit(-1)
			end

			ap spec, raw: true
			quit(0)
		end

		private_class_method def self.do_watch(_)
			begin
				StructCore::Watcher.watch(Dir.pwd)
			rescue SystemExit, Interrupt
				quit(0)
			end
			quit(0)
		end

		private_class_method def self.do_generate(_)
			selected_variants = ARGV.select { |item| item != '-g' && item != '--generate' }

			directory = Dir.pwd
			project_file = nil
			project_file = File.join(directory, 'project.yml') if File.exist? File.join(directory, 'project.yml')
			project_file = File.join(directory, 'project.json') if File.exist? File.join(directory, 'project.json')
			project_file = File.join(directory, 'Specfile') if File.exist? File.join(directory, 'Specfile')

			if project_file.nil?
				puts Paint['Could not find project.yml or project.json in the current directory', :red]
				quit(-1)
			end

			begin
				spec = nil
				spec = StructCore::Specfile.parse project_file unless project_file.end_with?('Specfile')
				spec = StructCore::SpecBuilder.build project_file if project_file.end_with?('Specfile')
				StructCore::XcodeprojWriter.write spec, directory, selected_variants unless spec.nil?
			rescue StandardError => err
				puts Paint[err, :red]
				quit(-1)
			end

			quit(0)
		end

		private_class_method def self.do_create(_)
			selected_option = Ask.list 'What do you want to create?', [
				'Class',
				'Struct',
				'Target',
				'Build Configuration'
			]

			if selected_option.zero?
				StructCore::Create::Class.run_interactive
			elsif selected_option == 1
				StructCore::Create::Struct.run_interactive
			elsif selected_option == 2
				StructCore::Create::Target.run_interactive
			elsif selected_option == 3
				StructCore::Create::Configuration.run_interactive
			end

			quit(0)
		end

		def self.do_migrate(_)
			args = ARGV.select { |item| item != '-m' && item != '--migrate' }

			mopts = Slop.parse(args) do |o|
				o.string '-p', '--path', 'specifies the path of the xcode project to migrate'
				o.string '-d', '--destination', 'specifies the destination folder to store the migrated project files'
				o.on '--help', 'help on using this command' do
					puts o
					quit(0)
				end
			end

			unless mopts.path? && mopts.destination?
				puts mopts
				quit(0)
			end

			StructCore::Migrator.migrate mopts[:path], mopts[:destination]
			quit(0)
		end
	end
end
