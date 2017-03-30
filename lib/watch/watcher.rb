require_relative '../spec/spec_file'
require_relative '../spec/processor/spec_processor'
require 'paint'
require 'listen'

module Listen
	class Record
		class SymlinkDetector
			def _fail(_, _)
				# Hide any warnings about duplicate watched directories
			end
		end
	end
end

module StructCore
	module Watcher
		def self.rebuild(project_file)
			StructCore::SpecProcessor.new(project_file, false).process
		rescue StandardError => err
			puts Paint[err, :red]
		end

		def self.watch(directory)
			project_file = nil
			project_file = File.join(directory, 'project.yml') if File.exist? File.join(directory, 'project.yml')
			project_file = File.join(directory, 'project.yaml') if File.exist? File.join(directory, 'project.yaml')
			project_file = File.join(directory, 'project.json') if File.exist? File.join(directory, 'project.json')
			project_file = File.join(directory, 'Specfile') if File.exist? File.join(directory, 'Specfile')

			if project_file.nil?
				puts Paint['Could not find a spec file in the current directory', :red]
				quit(-1)
			end

			rebuild(project_file)

			listener = Listen.to(directory, ignore: /\.xcodeproj/) do |modified, added, removed|
				if modified.include?(project_file) || !added.empty? || !removed.empty?
					rebuild(project_file)
				end
			end
			listener.start # not blocking
			puts Paint['All files and folders within this directory are now being watched for changes...', :green]
			sleep
		end
	end
end