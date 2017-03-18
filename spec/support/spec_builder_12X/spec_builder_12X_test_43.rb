def add_overrides
	override 'OVERRIDE', '1'
end

spec('1.2.0') do
	configuration('my-configuration') do
		profile 'general:debug'
		profile 'ios:debug'
		add_overrides
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		configuration do
			add_overrides
		end
	end
end