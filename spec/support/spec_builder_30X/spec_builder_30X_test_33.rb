spec('3.0.0') do
	configuration('debug') do
		source 'support_files/config.xcconfig'
	end
	configuration('release') do
		source 'support_files/config-release.xcconfig'
	end
	configuration('app store') do
		source 'support_files/config-release.xcconfig'
		type :release
	end
end