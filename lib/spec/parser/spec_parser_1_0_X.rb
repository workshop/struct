require 'semantic'

module StructCore
	class Specparser10X
		def parse_10x_target_references(target_opts, target_name, project_base_dir)
			return [] unless target_opts.key?('references')
			raw_references = target_opts['references']

			unless raw_references.is_a?(Array)
				puts Paint["Warning: Key 'references' for target #{target_name} is not an array. Ignoring...", :yellow]
				return []
			end

			raw_references.map { |raw_reference|
				if raw_reference.is_a?(Hash)
					unless raw_reference.key?('location')
						puts Paint['Warning: Invalid project reference detected. Ignoring...', :yellow]
						next nil
					end

					project_path = raw_reference['location']

					unless File.exist? File.join(project_base_dir, project_path)
						puts Paint["Warning: Project reference #{project_path} could not be found. Ignoring...", :yellow]
						next nil
					end

					next Specfile::Target::FrameworkReference.new(project_path, raw_reference)
				else
					# De-symbolise :sdkroot:-prefixed entries
					ref = raw_reference.to_s

					next Specfile::Target::TargetReference.new(raw_reference) unless ref.start_with? 'sdkroot:'

					next Specfile::Target::SystemFrameworkReference.new(raw_reference.sub('sdkroot:', '').sub('.framework', '')) if ref.end_with? '.framework'
					next Specfile::Target::SystemLibraryReference.new(raw_reference.sub('sdkroot:', ''))
				end
			}.compact
		end
	end
end