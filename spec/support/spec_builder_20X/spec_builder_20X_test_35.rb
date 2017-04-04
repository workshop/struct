spec('2.0.0') do
	configuration('debug') do
		source 'support_files/config.xcconfig'
	end
	configuration('release') do
		source 'support_files/config-release.xcconfig'
	end
	target('My app') do
		type :application
		source_dir 'support_files/abc'
		configuration('debug') do
			source 'support_files/config.xcconfig'
		end
		configuration('release') do
			source 'support_files/config-release.xcconfig'
		end
	end
end