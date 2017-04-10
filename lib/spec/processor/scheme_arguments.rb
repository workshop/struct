require_relative 'processor_component'
require 'slop'

module StructCore
	module Processor
		class SchemeArgumentsProcessor
			include ProcessorComponent

			def process(arguments)
				output = nil

				output = process_xc_arguments arguments if structure == :spec
				output = process_spec_arguments arguments if structure == :xcodeproj

				output
			end

			def process_xc_arguments(arguments) end

			# @param arguments [Hash]
			def process_spec_arguments(arguments)
				argv = Shellwords.shellwords(arguments || '').each_slice(2).to_a
				Xcodeproj::XCScheme::CommandLineArguments.new argv.map { |pair|
					k, v = pair
					Xcodeproj::XCScheme::CommandLineArgument.new(argument: "#{k} #{v}", enabled: true)
				}
			end
		end
	end
end