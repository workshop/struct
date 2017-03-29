require_relative 'processor_component'

module StructCore
	module Processor
		class TargetSourceFlagsComponent
			include ProcessorComponent

			def initialize(structure, working_directory, target = nil)
				super(structure, working_directory)
				@file_map = {}
				initialize_spec target if structure == :xcodeproj && !target.nil?
			end

			# @param target [StructCore::Specfile::Target]
			def initialize_spec(target)
				(target.options || []).each { |option|
					@file_map.merge!(Dir.glob(File.join(@working_directory, option.glob)).map { |file|
						[file, option.flags]
					}.to_h)
				}
			end

			def process(source)
				process_xc source if structure == :spec
				process_spec source if structure == :xcodeproj
			end

			def process_xc(source) end

			# @param source [Xcodeproj::Project::PBXBuildFile]
			def process_spec(source)
				file_ref = source.file_ref
				flags = @file_map[File.join(@working_directory, file_ref.hierarchy_path)]
				return if flags.nil?

				settings_hash = source.settings || {}
				settings_flags = settings_hash['COMPILER_FLAGS'] || ''
				settings_flags = "#{settings_flags} #{flags}"
				settings_hash['COMPILER_FLAGS'] = settings_flags

				source.settings = settings_hash
			end
		end
	end
end