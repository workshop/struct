require 'cocoapods'
require 'claide/argv'

module StructCore
	class CocoapodsInstaller
		def self.install_if_needed(spec, directory)
			return if spec.nil? || !spec.includes_pods || !directory.is_a?(String)

			Dir.chdir(directory) do
				installer = Pod::Command::Install.new(CLAide::ARGV.coerce([]))
				installer.send(:verify_podfile_exists!)
				installer = installer.send(:installer_for_config)
				installer.installation_options.integrate_targets = false
				installer.install!
			end
		end
	end
end