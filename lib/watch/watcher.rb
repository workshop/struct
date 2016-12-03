require_relative '../spec/spec_file'
require 'paint'

module Xcodegen
	module Watcher
		def watch(directory)
			begin
				spec_file = Xcodegen::Specfile.parse File.join(directory, 'project.yml')
			rescue StandardError => err
				puts Paint[err, :red]
				exit -1
			end

			puts spec_file
		end
	end
end