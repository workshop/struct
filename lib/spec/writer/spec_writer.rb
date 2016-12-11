require_relative 'spec_writer_1_0_X'

module Xcodegen
	class Specwriter
		def initialize
			@writers = []
		end

		def register(writer)
			if writer.respond_to?(:write_spec) && writer.respond_to?(:can_write_version) && writer.respond_to?(:write_target)
				@writers << writer
			else
				raise StandardError.new 'Unsupported writer object. Writer object must support :write and :can_write_version'
			end
		end

		def register_defaults
			@writers.unshift *[
				Xcodegen::Specwriter10X.new
			]
		end

		# @param spec [Xcodegen::Specfile]
		# @param path [String]
		def write_spec(spec, path)
			if @writers.length == 0
				register_defaults
			end

			raise StandardError.new 'Error: Invalid spec object. Spec object was nil.' unless spec != nil

			writer = @writers.find { |writer|
				writer.can_write_version(spec.version)
			}

			raise StandardError.new "Error: Invalid spec object. Project version #{spec.version.to_s} is unsupported by this version of xcodegen." unless writer != nil

			writer.write_spec(spec, path)
		end

		# @param target [Xcodegen::Specfile::Target]
		# @param spec_version [Semantic::Version]
		# @param path [String]
		def write_target(target, spec_version, path)
			if @writers.length == 0
				register_defaults
			end

			raise StandardError.new 'Error: Invalid target object. Target object was nil.' unless target != nil

			writer = @writers.find { |writer|
				writer.can_write_version(spec_version)
			}

			raise StandardError.new "Error: Invalid spec object. Project version #{spec_version.to_s} is unsupported by this version of xcodegen." unless writer != nil

			writer.write_target(target, path)
		end
	end
end