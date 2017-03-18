spec('1.3.0') do
	configuration('my-configuration') do
		profile 'general:debug'
		profile 'ios:debug'
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		configuration do end
	end
	variant('$base') do
		target('my-target') do
			source_dir 'support_files/def'
			i18n_resource_dir 'support_files/abc'
			exclude_files_matching '**/*.md'
			system_reference 'CoreData.framework'
			configuration do
				override 'SWIFT_ACTIVE_COMPILATION_CONDITIONS', 'APP_VARIANT_BASE'
			end
			script 'support_files/script.sh'
		end
	end
end