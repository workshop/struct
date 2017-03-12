spec('1.2.0') do
	configuration('debug') do
		profile 'general:debug'
		profile 'ios:debug'
	end
	target('target1') do end
end