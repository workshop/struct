require_relative '../spec_file'
require_relative '../../utils/defines'
require_relative '../../utils/ruby_2_0_monkeypatches'
require_relative '../../utils/xcconfig_parser'
require 'deep_clone'
require_relative 'processor_output'
require 'xcodeproj'
require 'semantic'
require 'yaml'

module StructCore
	module Processor
		module ProcessorComponent
			def initialize(structure, working_directory)
				@structure = structure
				@working_directory = working_directory
			end

			attr_accessor :structure
			attr_accessor :working_directory

			def process(*args) end
		end
	end
end