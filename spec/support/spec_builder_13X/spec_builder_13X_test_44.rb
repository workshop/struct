spec('1.3.0') do
	configuration('my-configuration') do
		profile 'general:debug'
		profile 'ios:debug'
		type 'debug'
	end
	target('my-target') do
		type :uuid => 'UUID'
		source_dir 'support_files/abc'
		configuration do end
	end
end