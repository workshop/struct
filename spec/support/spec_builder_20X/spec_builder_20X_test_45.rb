spec('2.0.0') do
	configuration('my-configuration') do
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		source_options '**/*.m', '-W'
		configuration do end
	end
	variant('beta') do
		target('my-target') do
			source_options '**/*.m', ''
		end
	end
end