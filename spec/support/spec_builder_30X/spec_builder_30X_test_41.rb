spec('3.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		configuration do end
	end
	variant('beta') do
		target('my-target') do
			include_cocoapods
		end
	end
end