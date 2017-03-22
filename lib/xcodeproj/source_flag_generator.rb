require_relative '../utils/ruby_2_0_monkeypatches'

module StructCore
	class SourceFlagGenerator
		def initialize
			@file_map = {}
			@options = []
			@project_dir = ''
		end

		# @param target [StructCore::Specfile::Target>]
		def preprocess(target, project_dir)
			@project_dir = project_dir
			@options = target.options || []

			@options.each { |option|
				@file_map.merge!(Dir.glob(File.join(project_dir, option.glob)).map { |file|
					[file, option.flags]
				}.to_h)
			}
		end

		# @param build_file [Xcodeproj::Project::Object::PBXBuildFile]
		def generate(build_file)
			file_ref = build_file.file_ref
			flags = @file_map[File.join(@project_dir, file_ref.hierarchy_path)]
			return if flags.nil?

			settings_hash = build_file.settings || {}
			settings_flags = settings_hash['COMPILER_FLAGS'] || ''
			settings_flags = "#{settings_flags} #{flags}"
			settings_hash['COMPILER_FLAGS'] = settings_flags

			build_file.settings = settings_hash
		end
	end
end