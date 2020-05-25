module StructCore
	class XcconfigParser
		def self.parse(xcconfig_file, project_dir)
			abs_xcconfig_file = xcconfig_file
			abs_xcconfig_file = xcconfig_file.slice(1, xcconfig_file.length) if xcconfig_file .start_with? '/'
			abs_xcconfig_file = File.join(project_dir, xcconfig_file) unless Pathname.new(abs_xcconfig_file).absolute?
			return {} if xcconfig_file.nil? || !File.exist?(abs_xcconfig_file)

			config_str = File.read abs_xcconfig_file
			config_str = config_str.gsub(/^\/\/.*\n/, '').sub("\n\n", "\n").gsub(/\s*=\s*/, '=')

			config = {}
			config_str.split("\n").each { |entry|
				pair = entry.split('=')
				next unless pair.length == 2
				key = pair[0]
				val = pair[1]

				# Most list-based values end in 'S' e.g. 'HEADER_SEARCH_PATHS'. Assume this is the case for now.
				if key.end_with?('S') && val.include?(' ') && val.include?('$(inherited)')
					val = val.split(' ')
				end

				config[key] = val
			}

			config
		end
	end
end