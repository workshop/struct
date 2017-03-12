require_relative '../utils/xcconfig_parser'
require 'deep_merge'

module StructCore
	class PodAssistant
		# @param spec [StructCore::Specfile]
		def self.apply_pod_configration(spec, project_dir)
			return unless spec.includes_pods

			spec.targets.each { |target|
				debug_xcconfig = StructCore::XcconfigParser.parse "Pods/Target Support Files/Pods-#{target.name}/Pods-#{target.name}.debug.xcconfig", project_dir
				release_xcconfig = StructCore::XcconfigParser.parse "Pods/Target Support Files/Pods-#{target.name}/Pods-#{target.name}.release.xcconfig", project_dir

				next if debug_xcconfig.empty? || release_xcconfig.empty?

				target.configurations.each { |c|
					project_config = spec.configurations.find { |pc| pc.name == c.name }
					next if project_config.nil?

					config = nil

					if project_config.type == 'debug'
						config = debug_xcconfig.dup
					elsif project_config.type == 'release'
						config = release_xcconfig.dup
					end

					config.deep_merge! c.settings
					c.settings = config
				}
			}
		end
	end
end