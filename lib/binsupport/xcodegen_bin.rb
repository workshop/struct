require 'slop'
require 'version'
require_relative '../watch/watcher'

module Xcodegen
	class XcodegenBin
		def self.run
			opts = Slop.parse do |o|
				o.on '-w', '--watch', 'watches your source dirs for changes and generates an xcode project' do
					begin
					Xcodegen::Watcher.watch(Dir.pwd)
					rescue SystemExit, Interrupt
						exit
					end
					exit
				end
				o.on '--version', 'print the version' do
					puts Xcodegen::VERSION
					exit
				end
			end

			puts opts
		end
	end
end