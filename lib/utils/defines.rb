require 'semantic'
require 'yaml'

module StructCore
	SPEC_VERSION_100 = Semantic::Version.new('1.0.0')
	SPEC_VERSION_110 = Semantic::Version.new('1.1.0')
	SPEC_VERSION_120 = Semantic::Version.new('1.2.0')
	SPEC_VERSION_121 = Semantic::Version.new('1.2.1')
	SPEC_VERSION_130 = Semantic::Version.new('1.3.0')
	SPEC_VERSION_200 = Semantic::Version.new('2.0.0')
	SPEC_VERSION_210 = Semantic::Version.new('2.1.0')
	SPEC_VERSION_220 = Semantic::Version.new('2.2.0')
	LATEST_SPEC_VERSION = SPEC_VERSION_220
	STRUCT_CONFIG_PROFILE_PATH = File.join(__dir__, '..', '..', 'res', 'config_profiles')
	XC_DEBUG_SETTINGS_MERGED = %w(general:debug ios:debug).map { |profile_name|
		[profile_name, File.join(STRUCT_CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
	}.map { |data|
		profile_name, profile_file_name = data
		unless File.exist? profile_file_name
			puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
			next nil
		end

		next YAML.load_file(profile_file_name)
	}.inject({}) { |settings, next_settings|
		settings.merge next_settings || {}
	}
	XC_RELEASE_SETTINGS_MERGED = %w(general:release ios:release).map { |profile_name|
		[profile_name, File.join(STRUCT_CONFIG_PROFILE_PATH, "#{profile_name.sub(':', '_')}.yml")]
	}.map { |data|
		profile_name, profile_file_name = data
		unless File.exist? profile_file_name
			puts Paint["Warning: unrecognised project configuration profile '#{profile_name}'. Ignoring...", :yellow]
			next nil
		end

		next YAML.load_file(profile_file_name)
	}.inject({}) { |settings, next_settings|
		settings.merge next_settings || {}
	}
	XC_CONFIGURATION_TYPE_MAP = { 'debug' => :debug, 'release' => :release, 'Debug' => :debug, 'Release' => :release }.freeze
	XC_CONFIG_PROFILE_PATH = File.join(__dir__, '..', '..', 'res', 'config_profiles')
	XC_TARGET_CONFIG_PROFILE_PATH = File.join(__dir__, '..', '..', 'res', 'target_config_profiles')
	XC_SCHEME_CONFIGURATION_MAP = {
		'Debug' => :debug,
		'Release' => :release
	}.freeze
	XC_PRETTY_PLATFORM_NAME_MAP = { 'ios' => 'iOS', 'mac' => 'macOS', 'watch' => 'watchOS', 'tv' => 'tvOS' }.freeze
end