require_relative 'processor_component'
require_relative '../../utils/defines'
require 'paint'
require 'deep_clone'

module StructCore
	module Processor
		class TargetCrossPlatformComponent
			include ProcessorComponent

			# @param project [StructCore::Specfile]
			def process(project)
				xplat_targets = project.targets.select { |t|
					t.configurations.any? { |c| c.is_a?(StructCore::Specfile::Target::PlatformScopedConfiguration) } ||
					t.res_dir.any? { |c| c.is_a?(StructCore::Specfile::Target::PlatformScopedResource) } ||
					t.references.any? { |c| c.is_a?(StructCore::Specfile::Target::PlatformScopedReference) }
				}

				return if xplat_targets.empty?

				project.targets = project.targets.select { |t|
					!xplat_targets.include? t
				}

				xplat_targets.each { |t| process_target t, project }
			end

			# rubocop:disable Metrics/AbcSize
			# @param original_target [StructCore::Specfile::Target]
			# @param project [StructCore::Specfile]
			def process_target(original_target, project)
				platforms = original_target.configurations.select { |c| c.is_a?(StructCore::Specfile::Target::PlatformScopedConfiguration) }.map(&:platform)
				platforms.unshift(*original_target.res_dir.select { |c| c.is_a?(StructCore::Specfile::Target::PlatformScopedResource) }.map(&:platform))
				platforms.unshift(*original_target.references.select { |c| c.is_a?(StructCore::Specfile::Target::PlatformScopedReference) }.map(&:platform))

				platforms.uniq!

				puts Paint["Warning: Invalid platforms were found for cross platform target: #{target.name}, any entries with invalid platforms will be ignored.", :yellow] unless
					platforms.select { |p| !%w(ios mac tv watch).include? p }.empty?

				platforms = platforms.select { |p| %w(ios mac tv watch).include? p }

				if platforms.empty?
					puts Paint["Warning: No valid platforms were found for cross platform target: #{target.name}, ignoring target."]
					return
				end

				project.targets = project.targets.unshift(*platforms.map { |platform|
					target = DeepClone.clone original_target
					target.name = "#{target.name}-#{XC_PRETTY_PLATFORM_NAME_MAP[platform]}"
					target.configurations = target.configurations.select { |c|
						!c.is_a?(StructCore::Specfile::Target::PlatformScopedConfiguration) || c.platform == platform
					}.map { |c|
						next c unless c.is_a?(StructCore::Specfile::Target::PlatformScopedConfiguration)
						c.configuration
					}
					target.res_dir = target.res_dir.select { |r|
						!r.is_a?(StructCore::Specfile::Target::PlatformScopedResource) || r.platform == platform
					}.map { |r|
						next r unless r.is_a?(StructCore::Specfile::Target::PlatformScopedResource)
						r.res_dir
					}
					target.references = target.references.select { |r|
						!r.is_a?(StructCore::Specfile::Target::PlatformScopedReference) || r.platform == platform
					}.map { |r|
						next r unless r.is_a?(StructCore::Specfile::Target::PlatformScopedReference)
						r.reference
					}

					target
				})
			end
			# rubocop:enable Metrics/AbcSize
		end
	end
end