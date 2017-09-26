spec('3.0.0') do
	configuration('my-configuration') do
		override 'OVERRIDE', '1'
		type 'debug'
	end
	target('my-target') do
	end
end