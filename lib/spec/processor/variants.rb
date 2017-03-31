require_relative 'processor_component'

module StructCore
	module Processor
		class VariantsComponent
			include ProcessorComponent

			# rubocop:disable Metrics/AbcSize
			# @param project [StructCore::Specfile]
			def process(project, variants = [])
				selected_variants = variants
				selected_variants ||= []

				variants = project.variants
				variants = variants.select { |v| selected_variants.include? v.name } unless selected_variants.empty?

				variants.map { |variant|
					next nil if variant.abstract

					variant_targets = DeepClone.clone variant.targets
					spec_targets = DeepClone.clone project.targets

					variant_targets.each { |target|
						spec_target = spec_targets.find { |st| st.name == target.name }
						next if spec_target.nil?

						spec_target.source_dir = spec_target.source_dir.push(*target.source_dir).uniq
						spec_target.res_dir = spec_target.res_dir.push(*target.res_dir).uniq
						spec_target.file_excludes = [].push(*spec_target.file_excludes).push(*target.file_excludes).uniq

						(target.configurations || []).each { |configuration|
							spec_config = spec_target.configurations.find { |sc| sc.name == configuration.name }
							spec_config.settings.merge! configuration.settings
							spec_config.profiles = [].push(*configuration.profiles).push(*spec_config.profiles).uniq
							spec_config.source = configuration.source
						}

						spec_target.file_excludes = [].push(*spec_target.file_excludes).push(*target.file_excludes)
						spec_target.options = [].push(*spec_target.options).push(*target.options)
						spec_target.references = [].push(*spec_target.references).push(*target.references)
						spec_target.prebuild_run_scripts = [].push(*spec_target.prebuild_run_scripts).push(*target.prebuild_run_scripts)
						spec_target.postbuild_run_scripts = [].push(*spec_target.postbuild_run_scripts).push(*target.postbuild_run_scripts)
					}

					name = variant.name
					name = 'project' if name == '$base'

					[name, StructCore::Specfile.new(project.version, spec_targets, project.configurations, [], project.base_dir, project.includes_pods)]
				}.compact.to_h
			end
			# rubocop:enable Metrics/AbcSize
		end
	end
end