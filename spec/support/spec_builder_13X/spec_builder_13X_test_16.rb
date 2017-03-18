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
		exclude_files_matching 123
		exclude_files_matching :a => 123
		configuration do end
	end
end