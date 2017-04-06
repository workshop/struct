spec('2.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'spec_builder_20X_test_12/abc'
		configuration do end
	end
end