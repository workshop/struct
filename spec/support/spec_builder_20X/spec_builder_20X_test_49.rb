spec('2.1.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-framework') do
		type :framework
		source_dir 'support_files/def'
		configuration do end
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		target_reference 'my-framework'
		configuration do end
	end
end