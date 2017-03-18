require_relative 'spec_parser_1_0_X'
require_relative 'spec_parser_1_1_X'
require_relative 'spec_parser_1_2_X'

module StructCore
	class Specparser
		def initialize
			@parsers = []
			@deprecated_versions = [
				StructCore::SPEC_VERSION_100
			]
		end

		def register(parser)
			if parser.respond_to?(:parse) && parser.respond_to?(:can_parse_version)
				@parsers << parser
				return
			end

			raise StandardError.new 'Unsupported parser object. Parser object must support :parse and :can_parse_version'
		end

		def register_defaults
			@parsers.unshift(
				StructCore::Specparser11X.new,
				StructCore::Specparser12X.new
			)
		end

		def deprecated?(version)
			@deprecated_versions.include? version
		end

		# There's not much sense refactoring this to be tiny methods.
		# rubocop:disable Metrics/PerceivedComplexity
		# rubocop:disable Metrics/AbcSize
		# @param path [String]
		def parse(path)
			register_defaults if @parsers.empty?

			filename = Pathname.new(path).absolute? ? path : File.join(Dir.pwd, path)
			raise StandardError.new "Error: Spec file #{filename} does not exist" unless File.exist? filename

			if filename.end_with?('yml', 'yaml')
				spec_hash = YAML.load_file filename
			elsif filename.end_with? 'json'
				spec_hash = JSON.parse File.read(filename)
			else
				raise StandardError.new 'Error: Unable to determine file format of project file'
			end

			raise StandardError.new "Error: Invalid spec file. No 'version' key was present." unless !spec_hash.nil? && spec_hash.key?('version')

			begin
				spec_version = Semantic::Version.new spec_hash['version']
			rescue StandardError => _
				raise StandardError.new 'Error: Invalid spec file. Project version is invalid.'
			end

			parser = @parsers.find { |parser|
				parser.can_parse_version(spec_version)
			}

			raise StandardError.new "Error: Invalid spec file. Project version #{spec_hash['version']} is unsupported by this version of struct." if parser.nil?
			puts Paint["Spec version #{spec_version} is now deprecated and will be removed soon. Please migrate to the latest spec format as soon as possible.", :red] if deprecated?(spec_version)

			raise StandardError.new "Error: Invalid spec file. No 'configurations' key was present." unless spec_hash.key? 'configurations'
			raise StandardError.new "Error: Invalid spec file. Key 'configurations' should be a hash" unless spec_hash['configurations'].is_a?(Hash)
			raise StandardError.new 'Error: Invalid spec file. Project should have at least one configuration' unless spec_hash['configurations'].keys.count > 0

			parser.parse(spec_version, spec_hash, filename)
		end
		# rubocop:enable Metrics/PerceivedComplexity
		# rubocop:enable Metrics/AbcSize
	end
end