require_relative '../utils/xcconfig_parser'
require 'deep_merge'

module StructCore
	class PodAssistant
		# @param spec [StructCore::Specfile]
		def self.apply_pod_configuration(spec, project_dir)
			return unless spec.includes_pods

			spec.targets.each { |target|
				debug_xcconfig = StructCore::XcconfigParser.parse "Pods/Target Support Files/Pods-#{target.name}/Pods-#{target.name}.debug.xcconfig", project_dir
				release_xcconfig = StructCore::XcconfigParser.parse "Pods/Target Support Files/Pods-#{target.name}/Pods-#{target.name}.release.xcconfig", project_dir

				next if debug_xcconfig.empty? || release_xcconfig.empty?

				target.configurations.each { |target_config|
					merge_config_pod_settings spec, debug_xcconfig, release_xcconfig, target_config
				}

				pod_ref_options = {}
				pod_ref_options['frameworks'] = []
				pod_ref_framework = {}
				pod_ref_framework['name'] = "Pods-#{target.name}.framework"
				pod_ref_options['frameworks'] << pod_ref_framework
				pod_ref = StructCore::Specfile::Target::FrameworkReference.new(File.join(project_dir, 'Pods/Pods.xcodeproj'), pod_ref_options)

				check_lock_script_path = File.join(File.dirname(__FILE__), '../../res/run_script_phases/cp_check_pods_manifest.lock.sh')
				check_lock_script = StructCore::Specfile::Target::RunScript.new(check_lock_script_path)
				embed_frameworks = StructCore::Specfile::Target::RunScript.new("Pods/Target Support Files/Pods-#{target.name}/Pods-#{target.name}-frameworks.sh")
				copy_resources = StructCore::Specfile::Target::RunScript.new("Pods/Target Support Files/Pods-#{target.name}/Pods-#{target.name}-resources.sh")

				target.references.push pod_ref
				target.prebuild_run_scripts << check_lock_script
				target.postbuild_run_scripts << embed_frameworks
				target.postbuild_run_scripts << copy_resources
			}
		end

		def self.merge_config_pod_settings(spec, debug_xcconfig, release_xcconfig, target_config)
			project_config = spec.configurations.find { |pc| pc.name == target_config.name }
			return if project_config.nil?

			config = nil

			if project_config.type == 'debug'
				config = debug_xcconfig.dup
			elsif project_config.type == 'release'
				config = release_xcconfig.dup
			end

			config.deep_merge! target_config.settings
			target_config.settings = config
		end
	end
end