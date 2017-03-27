require_relative 'processor_component'

module StructCore
	module Processor
		class TargetPlatformComponent
			include ProcessorComponent

			def process(target)
				output = nil
				output = process_xc_target target if structure == :spec
				output = process_spec_target target if structure == :xcodeproj

				output
			end

			# @param target [Xcodeproj::Project::PBXNativeTarget]
			def process_xc_target(target)
				config = target.build_configurations.first
				return nil if config.nil?

				sdk = config.build_settings['SDKROOT']
				return nil if sdk.nil?

				if sdk.include? 'iphoneos'
					platform = 'ios'
				elsif sdk.include? 'macosx'
					platform = 'mac'
				elsif sdk.include? 'appletvos'
					platform = 'tv'
				elsif sdk.include? 'watchos'
					platform = 'watch'
				else
					puts Paint["Warning: SDKROOT #{build_settings['SDKROOT']} not recognised in configuration for target: '#{target.name}'. Ignoring...", :yellow]
					return nil
				end

				platform
			end

			# @param target [StructCore::Specfile::Target]
			def process_spec_target(target)
				profile = target.configurations.first.profiles.find { |profile| profile.include? 'platform:' }
				sdk = nil
				sdk = YAML.load_file(File.join(XC_TARGET_CONFIG_PROFILE_PATH, "#{profile.sub(':', '_')}.yml"))['SDKROOT'] unless profile.nil?
				sdk = target.configurations.first.settings['SDKROOT'] if sdk.nil?

				if sdk.include? 'iphoneos'
					platform = :ios
				elsif sdk.include? 'macosx'
					platform = :osx
				elsif sdk.include? 'appletvos'
					platform = :tvos
				elsif sdk.include? 'watchos'
					platform = :watchos
				else
					puts Paint["Warning: SDKROOT #{build_settings['SDKROOT']} not recognised in configuration for target: '#{target.name}'. Ignoring...", :yellow]
					return nil
				end

				platform
			end
		end
	end
end