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
					directory = Dir.pwd
					if File.exist? File.join(directory, 'project.yml')
						project_file = File.join(directory, 'project.yml')
					elsif File.exist? File.join(directory, 'project.json')
						project_file = File.join(directory, 'project.json')
					else
						project_file = nil
					end

					if project_file == nil
						puts Paint['Could not find project.yml or project.json in the current directory', :red]
						quit -1
					end

					begin
						spec = StructCore::Specfile.parse project_file
					rescue StandardError => err
						puts Paint[err, :red]
						quit -1
					end

					ap spec, options = {:raw => true}
					quit 0
				end
				o.on '-w', '--watch', 'watches your source dirs for changes and generates an xcode project' do
					begin
					StructCore::Watcher.watch(Dir.pwd)
					rescue SystemExit, Interrupt
						quit 0
					end
					quit 0
				end
				o.on '-g', '--generate', 'generates an xcode project' do
					directory = Dir.pwd
					if File.exist? File.join(directory, 'project.yml')
						project_file = File.join(directory, 'project.yml')
					elsif File.exist? File.join(directory, 'project.json')
						project_file = File.join(directory, 'project.json')
					else
						project_file = nil
					end

					if project_file == nil
						puts Paint['Could not find project.yml or project.json in the current directory', :red]
						quit -1
					end

					begin
						spec = StructCore::Specfile.parse project_file
						StructCore::XcodeprojWriter.write spec, directory
					rescue StandardError => err
						puts Paint[err, :red]
						quit -1
					end

					quit 0
				end
				o.on '-c', '--create', 'starts the resource creation wizard for creating files, targets, etc.' do
					selected_option = Ask.list 'What do you want to create?', [
						'Class',
						'Struct',
						'Target',
						'Build Configuration'
					]

					if selected_option == 0
						StructCore::Create::Class.run_interactive
					elsif selected_option == 1
						StructCore::Create::Struct.run_interactive
					elsif selected_option == 2
						StructCore::Create::Target.run_interactive
					elsif selected_option == 3
						StructCore::Create::Configuration.run_interactive
					end

					quit 0
				end
				o.on '-m', '--migrate', 'migrates an Xcode project and its files to a specfile (beta)' do
					args = ARGV.select { |item| item != '-m' && item != '--migrate' }

					mopts = Slop.parse(args) do |mopts|
						mopts.string '-p', '--path', 'specifies the path of the xcode project to migrate'
						mopts.string '-d', '--destination', 'specifies the destination folder to store the migrated project files'
						mopts.on '--help', 'help on using this command' do
							puts mopts
							quit 0
						end
					end

					unless mopts.path? && mopts.destination?
						puts mopts
						quit 0
					end

					StructCore::Migrator.migrate mopts[:path], mopts[:destination]
					quit 0
				end
				o.on '--version', 'print the version' do
					puts StructCore::VERSION
					quit 0
				end
			end

			puts opts
			quit 0
		end
	end
end
