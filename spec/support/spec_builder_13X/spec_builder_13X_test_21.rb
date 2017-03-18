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
		project_framework_reference(123) do
			framework 'abc'
		end
		configuration do end
	end
end