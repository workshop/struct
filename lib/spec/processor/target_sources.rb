require_relative 'processor_component'
require_relative 'target_source'
require_relative 'target_source_flags'

module StructCore
	module Processor
		class TargetSourcesComponent
			include ProcessorComponent

			def initialize(structure, working_directory)
				super(structure, working_directory)
				@source_component = TargetSourceComponent.new(@structure, @working_directory)
			end

			def process(target, target_dsl = nil, dsl = nil)
				output = []

				output = process_xc_sources target, target_dsl if structure == :spec && !target_dsl.nil?
				output = process_spec_sources target, target_dsl, dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil?

				output
			end

			# @param target [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param target_dsl [StructCore::Specfile::Target]
			def process_xc_sources(target, target_dsl)
				target_files = target.source_build_phase.files.map(&:file_ref)
				target_files.unshift(*target.resources_build_phase.files.map { |file|
					next nil if file.file_ref.nil?
					file.file_ref
				}.compact.select { |file_ref|
					file = file_ref.real_path.to_s
					!file.include?('.xcassets/') &&
						!file.include?('.bundle/') &&
						!file.include?('.xcdatamodeld/') &&
						!file.include?('.framework/') &&
						!file.end_with?('Info.plist') &&
						!file.include?('.lproj') &&
						!file.end_with?('.xib') &&
						!file.end_with?('.storyboard') &&
						!file.end_with?('.strings') &&
						file.include?('.')
				})

				process_xc_build_flags target, target_dsl

				target_files.map { |source|
					source_entry = @source_component.process source
					source_entry
				}
			end

			# @param target [StructCore::Specfile::Target]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_sources(target, target_dsl, dsl)
				all_source_files = glob_sources(target).select { |file|
					!(target.file_excludes.any? { |exclude|
						File.fnmatch(exclude, file.slice(@working_directory.length + 1..-1), File::FNM_PATHNAME | File::FNM_EXTGLOB)
					})
				}

				flags_component = TargetSourceFlagsComponent.new @structure, @working_directory, target

				all_source_files.each { |file|
					source_dir = File.dirname file
					rel_source_root = source_dir.sub(@working_directory, '')
					rel_source_root[0] = '' if rel_source_root.start_with? '/'

					source_dir_component = File.basename(source_dir)
					source_group = dsl.groups.find { |g| g.path == source_dir_component }
					source_group ||= dsl.new_group(source_dir_component, rel_source_root, 'SOURCE_ROOT')

					file_dsl = @source_component.process file, target_dsl, source_group
					flags_component.process file_dsl if file_dsl.is_a?(Xcodeproj::Project::Object::PBXBuildFile)
				}
			end

			# @param target [StructCore::Specfile::Target]
			def glob_sources(target)
				all_source_files = []
				source_files_minus_dir = []

				target.source_dir.reverse.each { |source_dir|
					# For some reason our symlink-traversing glob duplicates the results, so we use .uniq to fix that
					new_files = Dir.glob("#{source_dir}/**{,/*/**}/*").select { |file|
						!file.include?('.xcassets/') &&
							!file.include?('.bundle/') &&
							!file.include?('.xcdatamodeld/') &&
							!file.include?('.framework/') &&
							!file.end_with?('Info.plist') &&
							!file.include?('.lproj') &&
							file.include?('.')
					}.uniq.select { |f|
						source_files_minus_dir.count(f.sub(source_dir, '')).zero?
					}

					new_files_minus_dir = new_files.map { |f| f.sub(source_dir, '') }
					all_source_files.push(*new_files)
					source_files_minus_dir = source_files_minus_dir.push(*new_files_minus_dir).uniq
				}

				all_source_files
			end

			# @param target [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param target_dsl [StructCore::Specfile::Target]
			def process_xc_build_flags(target, target_dsl)
				flags_component = TargetSourceFlagsComponent.new @structure, @working_directory, target
				target.source_build_phase.files.each { |build_file|
					option = flags_component.process(build_file)
					target_dsl.options << option unless option.nil?
				}
			end
		end
	end
end