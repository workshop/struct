spec('1.3.0') do
	configuration('debug') do
		profile 'general:debug'
		profile 'ios:debug'
	end
	target('target1') do end
end