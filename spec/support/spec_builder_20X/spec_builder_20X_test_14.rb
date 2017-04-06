spec('2.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/spec_builder_20X_test_14/abc'
		i18n_resource_dir 'support_files/spec_builder_20X_test_14/abc'
		configuration do end
	end
end