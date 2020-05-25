require 'slop'
require_relative '../version'
require 'paint'
require 'awesome_print'
require 'inquirer'
require_relative '../utils/defines'
require_relative '../refresher/refresher'
require_relative '../watch/watcher'
require_relative '../spec/spec_file'
require_relative '../spec/builder/spec_builder'
require_relative '../spec/processor/spec_processor'

module StructCore
	class CLI
		def self.quit(code)
			StructCore::Refresher.run
			exit code
		end

		def self.run
			opts = nil
			begin
				opts = Slop.parse do |o|
					o.on 'p', 'parse', 'parses a spec file and prints the output' do
						return do_parse o
					end
					o.on 'w', 'watch', 'watches your source dirs for changes and generates an xcode project' do
						return do_watch o
					end
					o.on 'g', 'generate', 'generates an xcode project' do
						return do_generate o
					end
					o.on 'm', 'migrate', 'migrates an Xcode project and its files to a specfile (beta)' do
						return do_migrate o
					end
					o.on '-v', '--version', 'print the version' do
						puts StructCore::VERSION
						quit(0)
					end
				end
			rescue StandardError => err
				puts err
			end

			puts opts
			quit(0)
		end

		def self.do_parse(_)
			directory = Dir.pwd

			project_file = nil
			project_file = File.join(directory, 'project.yml') if File.exist? File.join(directory, 'project.yml')
			project_file = File.join(directory, 'project.yaml') if File.exist? File.join(directory, 'project.yaml')
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

		def self.do_watch(_)
			begin
				StructCore::Watcher.watch(Dir.pwd)
			rescue SystemExit, Interrupt
				quit(0)
			end
			quit(0)
		end

		def self.do_generate(_)
			args = ARGV.select { |item| !%w(-g --generate g generate).include? item }
			options = args.select { |item| item.start_with? '--' }
			selected_variants = args.select { |item| !item.start_with? '--' }

			directory = Dir.pwd
			project_file = nil
			project_file = File.join(directory, 'project.yml') if File.exist? File.join(directory, 'project.yml')
			project_file = File.join(directory, 'project.yaml') if File.exist? File.join(directory, 'project.yaml')
			project_file = File.join(directory, 'project.json') if File.exist? File.join(directory, 'project.json')
			project_file = File.join(directory, 'Specfile') if File.exist? File.join(directory, 'Specfile')

			if project_file.nil?
				puts Paint['Could not find a spec file in the current directory', :red]
				quit(-1)
			end

			begin
				StructCore::SpecProcessor.new(project_file, options.include?('--dry-run'), selected_variants).process
			rescue StandardError => err
				puts Paint[err, :red]
				quit(-1)
			end

			quit(0)
		end

		def self.do_migrate(_)
			args = ARGV.select { |item| item != '-m' && item != '--migrate' }

			mopts = Slop.parse(args) do |o|
				o.string '-p', '--path', 'specifies the path of the xcode project to migrate'
				o.bool '--dry-run'
				o.on '--help', 'help on using this command' do
					puts o
					quit(0)
				end
			end

			unless mopts.path?
				puts mopts
				quit(0)
			end

			StructCore::SpecProcessor.new(mopts[:path], mopts.dry_run?).process
			quit(0)
		end

		private_class_method :do_parse
		private_class_method :do_watch
		private_class_method :do_generate
		private_class_method :do_migrate
	end
end
