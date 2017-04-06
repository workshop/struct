spec('2.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		source_dir 'spec_parser_20X_test_12/abc'
	end
end