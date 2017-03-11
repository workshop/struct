require_relative 'spec_builder_dsl'
require_relative '../../spec/spec_file'

module StructCore
	class SpecBuilder
		# @param path [String]
		def self.build(path)
			filename = Pathname.new(path).absolute? ? path : File.join(Dir.pwd, path)
			raise StandardError.new "Error: Spec file #{filename} does not exist" unless File.exist? filename

			builder_dsl = StructCore::SpecBuilderDsl.new(StructCore::Specfile.new(nil, [], [], [], File.dirname(filename)))
			builder_dsl.instance_eval(File.read(filename))
			builder_dsl.build
		end
	end
end