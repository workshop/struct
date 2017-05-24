module StructCore
	module Utils20X
		def configurations_valid?(configurations, config_names)
			return config_names.empty? if configurations.empty?

			return configurations.length == config_names.length unless configurations.any? { |c|
				c.is_a? StructCore::Specfile::Target::PlatformScopedConfiguration
			}

			true
		end
	end
end