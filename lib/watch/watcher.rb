require_relative '../spec/spec_file'
require_relative '../xcodeproj/xcodeproj_writer'
require 'paint'
require 'listen'

module Xcodegen
	module Watcher
		def self.rebuild(project_file, directory)
			begin
				spec = Xcodegen::Specfile.parse project_file
			rescue StandardError => err
				puts Paint[err, :red]
				exit -1
			end

			begin
				Xcodegen::XcodeprojWriter.write spec, directory
			rescue StandardError => err
				puts Paint[err, :red]
			end
		end

		def self.watch(directory)
			if File.exist? File.join(directory, 'project.yml')
				project_file = File.join(directory, 'project.yml')
			else
				project_file = File.join(directory, 'project.json')
			end

			rebuild(project_file, directory)

			listener = Listen.to(directory, ignore: /project\.xcodeproj/) do |modified, added, removed|
				if modified.include? project_file or added.length > 0 or removed.length > 0
					rebuild(project_file, directory)
				end
			end
			listener.start # not blocking
			puts Paint['All files and folders within this directory are now being watched for changes...', :green]
			sleep
		end
	end
end