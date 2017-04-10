spec('2.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		configuration do end
	end
	scheme('my-target') do
		analyze do
			configuration do
				override 'IPHONEOS_DEPLOYMENT_TARGET', '10.0'
			end
		end

		archive name: 'MyApp.xcarchive', reveal: true

		build do
			parallelize_builds
			build_implicit
			target('my-target') do
				enable_archiving
				enable_running
				enable_profiling
				enable_testing
			end
		end

		tests('debug') do
			target 'my-target'
			inherit_launch_arguments
			enable_code_coverage
			environment do
				override 'OS_ACTIVITY_MODE', 'disable'
			end
		end

		launch('my-target') do
			enable_location_simulation
			arguments '-AppleLanguages (en-GB)'
			environment do
				override 'OS_ACTIVITY_MODE', 'disable'
			end
		end

		profile('my-target') do
			configuration do
				override 'IPHONEOS_DEPLOYMENT_TARGET', '10.0'
			end
			inherit_environment
		end
	end
end