spec('3.0.0') do
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
		target_reference 'my-framework', copy: true, codeSignOnCopy: true
		configuration do end
	end
end