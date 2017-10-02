require_relative 'processor_component'

module StructCore
	module Processor
		class TargetConfigurationsLinterComponent
			include ProcessorComponent

			# @param project [StructCore::Specfile]
			def process(project)
				lint_framework_search_paths project
			end

			# @param project [StructCore::Specfile]
			def lint_framework_search_paths(project)
				project.targets.each { |t|
					search_paths = t.configurations.map { |c|
						(c.settings || {})['FRAMEWORK_SEARCH_PATHS'] || []
					}.map { |p|
						next [p] if p.is_a?(String)
						next p if p.is_a?(String)
						nil
					}.compact.map { |p|
						# If a search path is a symlink, we need to resolve the original directory for this lint check
						Pathname.new(p).realpath.to_s
					}

					t.references.select { |r| r.is_a?(LocalFrameworkReference) }.select { |ref|
						framework_path = ref.framework_path
						framework_dir = File.dirname framework_path
						!search_paths.contains { |search_dir| framework_dir.include? search_dir }
					}.each { |ref|
						puts Paint["Warning: Framework #{File.basename(ref.framework_path)} is not included in your FRAMEWORK_SEARCH_PATHS. Xcode will not be able to resolve this framework", :yellow]
					}
				}
			end

			private :lint_framework_search_paths
		end
	end
end