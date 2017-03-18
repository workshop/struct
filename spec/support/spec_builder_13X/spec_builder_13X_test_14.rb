spec('1.3.0') do
	configuration('my-configuration') do
		profile 'general:debug'
		profile 'ios:debug'
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/spec_builder_13X_test_14/abc'
		i18n_resource_dir 'support_files/spec_builder_13X_test_14/abc'
		configuration do end
	end
end