spec('3.0.0') do
	configuration('my-configuration') do
		type 'debug'
	end
	target('my-target') do
		type :uuid => 'UUID'
		source_dir 'support_files/abc'
		configuration do end
	end
end