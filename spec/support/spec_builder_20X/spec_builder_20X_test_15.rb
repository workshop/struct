spec('2.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		exclude_files_matching 'a/b/c'
		exclude_files_matching 'd/e/f'
		configuration do end
	end
end