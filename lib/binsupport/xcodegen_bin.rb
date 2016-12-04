require 'slop'
require 'version'
require 'paint'
require 'awesome_print'
require_relative '../watch/watcher'
require_relative '../spec/spec_file'
require_relative '../xcodeproj/xcodeproj_writer'

module Xcodegen
	class XcodegenBin
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
						exit -1
					end

					begin
						spec = Xcodegen::Specfile.parse project_file
					rescue StandardError => err
						puts Paint[err, :red]
						exit -1
					end

					ap spec, options = {:raw => true}
					exit 0
				end
				o.on '-w', '--watch', 'watches your source dirs for changes and generates an xcode project' do
					begin
					Xcodegen::Watcher.watch(Dir.pwd)
					rescue SystemExit, Interrupt
						exit 0
					end
					exit 0
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
						exit -1
					end

					begin
						spec = Xcodegen::Specfile.parse project_file
						Xcodegen::XcodeprojWriter.write spec, File.join(directory, 'project.xcodeproj')
					rescue StandardError => err
						puts Paint[err, :red]
						exit -1
					end

					puts Paint["Generated project.xcodeproj from #{File.basename(project_file)}", :green]
					exit 0
				end
				o.on '--version', 'print the version' do
					puts Xcodegen::VERSION
					exit 0
				end
			end

			puts opts
		end
	end
end