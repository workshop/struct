require_relative 'processor_component'
require_relative '../../utils/xcodeproj_monkeypatches'

module StructCore
	module Processor
		class TargetFrameworkReferenceComponent
			include ProcessorComponent

			def process(ref, target, target_dsl = nil, group_dsl = nil)
				output = nil

				output = process_xc_ref ref, target if structure == :spec
				output = process_spec_ref ref, target, target_dsl, group_dsl if structure == :xcodeproj && !target_dsl.nil? && !group_dsl.nil?

				output
			end

			def process_xc_ref(ref, target) end

			# @param ref [StructCore::Specfile::Target::LocalFrameworkReference]
			# @param target [StructCore::Specfile::Target]
			# @param target_dsl [Xcodeproj::Project::Object::PBXNativeTarget]
			# @param group_dsl [Xcodeproj::Project::Object::PBXGroup]
			def process_spec_ref(ref, target, target_dsl, group_dsl)
				subproj_group = target_dsl.project.frameworks_group.groups.find { |g| g.display_name == '$subproj' }
				subproj_group = target_dsl.project.frameworks_group.new_group '$subproj', nil, '<group>' if subproj_group.nil?

				subproj = subproj_group.struct__new_reference File.realpath(ref.project_path), :group
				remote_project = Xcodeproj::Project.open ref.project_path

				ref.settings['frameworks'].each { |f_opts|
					add_remote_framework remote_project, subproj, target, group_dsl, target_dsl, f_opts, ref
				}
			end

			def find_remote_target(remote_project, target, f_opts)
				remote_project.targets.select { |t|
					next nil if target.configurations.empty?
					profile_name = nil
					profile_name = "platform:#{t.platform_name}" unless t.platform_name.nil?
					next t.product_reference.path == f_opts['name'] && t.product_type == 'com.apple.product-type.framework' && target.configurations.first.profiles.include?(profile_name)
				}.compact.first
			end

			def add_remote_framework(remote_project, subproj, target, group_dsl, target_dsl, f_opts, ref)
				remote_target = find_remote_target remote_project, target, f_opts
				return if remote_target.nil?

				framework = subproj.file_reference_proxies.select { |p| p.path == remote_target.product_reference.path }.first

				framework_path = File.expand_path framework.path, File.dirname(ref.project_path)
				group_dsl.new_file framework_path

				target_dsl.add_dependency remote_target

				if f_opts['copy']
					embed_phase = target_dsl.project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
					embed_phase.name = "Embed Framework #{framework.path}"
					embed_phase.symbol_dst_subfolder_spec = :frameworks
					target_dsl.build_phases.insert(target_dsl.build_phases.count, embed_phase)

					attributes = ['RemoveHeadersOnCopy']

					attributes << 'CodeSignOnCopy' if f_opts['codeSignOnCopy']

					framework_build_file = embed_phase.add_file_reference framework
					framework_build_file.settings = { 'ATTRIBUTES' => attributes }
				end

				target_dsl.frameworks_build_phase.add_file_reference framework
			end
		end
	end
end
