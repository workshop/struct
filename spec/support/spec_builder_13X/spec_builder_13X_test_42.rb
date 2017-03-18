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
		library_reference 'support_files/library.a'
	end
	variant('beta') do
		target('my-target') do
			library_reference 'support_files/library.a'
		end
	end
end