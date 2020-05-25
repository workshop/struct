require_relative 'processor_component'
require_relative 'target_resource'

module StructCore
	module Processor
		class TargetResourcesComponent
			include ProcessorComponent

			def initialize(structure, working_directory, resource_component = nil)
				super(structure, working_directory)
				@resource_component = resource_component
				@resource_component ||= TargetResourceComponent.new(@structure, @working_directory)
			end

			def process(target, target_dsl = nil, dsl = nil)
				output = []

				output = process_xc_resources target if structure == :spec
				output = process_spec_resources target, target_dsl, dsl if structure == :xcodeproj && !target_dsl.nil? && !dsl.nil?

				output
			end

			# @param target [Xcodeproj::Project::Object::PBXNativeTarget]
			def process_xc_resources(target)
				target.resources_build_phase.files.select { |f|
					!f.file_ref.name.nil? && f.file_ref.name.end_with?('.storyboard', '.strings', '.stringsdict')
				}.map { |ref|
					@resource_component.process ref.file_ref
				}.compact.uniq
			end

			# @param target [StructCore::Specfile::Target]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param dsl [Xcodeproj::Project]
			def process_spec_resources(target, target_dsl, dsl)
				target.res_dir.select { |res_dir|
					lfiles = Dir.glob(File.join(res_dir, '*.lproj', '**', '*'))
					next if lfiles.empty?
					resource_group = create_resource_group target, dsl

					# Create a virtual path since lproj files go through a layer of indirection before hitting the filesystem
					lproj_variant_files = map_lproj_entries lfiles, res_dir
					lproj_variant_files.each { |lproj_file|
						variant_group = resource_group.new_variant_group(lproj_file, res_dir, '<group>')

						# Add all lproj files to the variant group
						Dir.glob(File.join(res_dir, '*.lproj', lproj_file)).each { |file|
							@resource_component.process file, target_dsl, variant_group
						}
					}
				}
			end

			def create_resource_group(target, dsl)
				resource_group = dsl.groups.find { |group| group.display_name == "$lang:#{target.name}" }
				return resource_group unless resource_group.nil?

				resource_group = dsl.new_group("$lang:#{target.name}", nil, '<group>')
				resource_group.source_tree = 'SOURCE_ROOT'

				resource_group
			end

			def map_lproj_entries(lfiles, res_dir)
				lproj_variant_files = []
				lfiles.map { |lfile|
					new_lfile = lfile.sub(res_dir, '')
					new_lfile = new_lfile.slice(1, new_lfile.length) if new_lfile.start_with? '/'
					next new_lfile
				}.each { |lfile|
					lfile_components = lfile.split('/')
					lfile_lproj_idx = lfile_components.index { |component|
						component.include? '.lproj'
					}

					lfile_variant_components = []
					lfile_variant_components.push(*lfile_components)
					lfile_variant_components.shift(lfile_lproj_idx + 1)
					lfile_variant_path = lfile_variant_components.join('/')
					unless lproj_variant_files.include? lfile_variant_path
						lproj_variant_files << lfile_variant_path
					end
				}

				lproj_variant_files
			end

			private :create_resource_group
			private :map_lproj_entries
		end
	end
end