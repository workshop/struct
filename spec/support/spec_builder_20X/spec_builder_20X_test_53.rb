spec('2.2.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target 'my-target' do
		type :application
		platform 'ios' do
			source_dir 'MyApp'
			source_dir 'MyApp-ios'

			configuration 'my-configuration' do
				override 'IPHONEOS_DEPLOYMENT_TARGET', '9.1'
			end
		end
		platform 'mac' do
			source_dir 'MyApp'
			source_dir 'MyApp-mac'

			configuration 'my-configuration' do
				override 'IPHONEOS_DEPLOYMENT_TARGET', '9.1'
			end
		end
	end
end