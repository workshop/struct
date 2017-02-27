require_relative 'spec_writer_1_0_X'
require_relative 'spec_writer_1_1_X'

module StructCore
	class Specwriter
		def initialize
			@writers = []
		end

		def register(writer)
			if writer.respond_to?(:write_spec) && writer.respond_to?(:can_write_version) && writer.respond_to?(:write_target)
				@writers << writer
				return
			end

			raise StandardError.new 'Unsupported writer object. Writer object must support :write and :can_write_version'
		end

		def register_defaults
			@writers.unshift(
				StructCore::Specwriter10X.new,
				StructCore::Specwriter11X.new
			)
		end

		# @param spec [StructCore::Specfile]
		# @param path [String]
		def write_spec(spec, path)
			register_defaults if @writers.empty?
			raise StandardError.new 'Error: Invalid spec object. Spec object was nil.' if spec.nil?

			writer = @writers.find { |writer|
				writer.can_write_version(spec.version)
			}

			raise StandardError.new "Error: Invalid spec object. Project version #{spec.version} is unsupported by this version of struct." if writer.nil?

			writer.write_spec(spec, path)
		end

		# @param configuration [StructCore::Specfile::Configuration]
		# @param spec_version [Semantic::Version]
		# @param path [String]
		def write_configuration(configuration, spec_version, path)
			register_defaults if @writers.empty
			raise StandardError.new 'Error: Invalid configuration object. Configuration object was nil.' if configuration.nil?

			writer = @writers.find { |writer|
				writer.can_write_version(spec_version)
			}

			raise StandardError.new "Error: Invalid spec version. Project version #{spec_version} is unsupported by this version of struct." if writer.nil?

			writer.write_configuration(configuration, path)
		end

		# @param target [StructCore::Specfile::Target]
		# @param spec_version [Semantic::Version]
		# @param path [String]
		def write_target(target, spec_version, path)
			register_defaults if @writers.empty?
			raise StandardError.new 'Error: Invalid target object. Target object was nil.' if target.nil?

			writer = @writers.find { |writer|
				writer.can_write_version(spec_version)
			}

			raise StandardError.new "Error: Invalid spec version. Project version #{spec_version} is unsupported by this version of struct." if writer.nil?

			writer.write_target(target, path)
		end
	end
end
