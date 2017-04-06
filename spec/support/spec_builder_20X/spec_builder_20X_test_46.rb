spec('2.0.0') do
	configuration('my-configuration') do
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		configuration('my-configuration') do
			override 'INFOPLIST_FILE', 'Info.plist'
		end
		configuration('$base') do
			override 'IPHONEOS_DEPLOYMENT_TARGET', '10.2'
		end
	end
end