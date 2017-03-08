module StructCore
	class XcconfigParser
		def self.parse(xcconfig_file, project_dir)
			xcconfig_file[0] = '' if xcconfig_file .start_with? '/'
			abs_xcconfig_file = xcconfig_file
			abs_xcconfig_file = File.join(project_dir, xcconfig_file) unless Pathname.new(xcconfig_file).absolute?
			return {} if xcconfig_file.nil? || !File.exist?(abs_xcconfig_file)

			config_str = File.read abs_xcconfig_file
			config_str = config_str.gsub(/^\/\/.*\n/, '').sub("\n\n", "\n").gsub(/\s*=\s*/, '=')

			config = {}
			config_str.split("\n").each { |entry|
				pair = entry.split('=')
				next unless pair.length == 2
				config[pair[0]] = pair[1]
			}

			config
		end
	end
end