spec('1.3.0') do
	configuration('debug') do
		profile 'general:debug'
		profile 'ios:debug'
	end

	configuration('release') do
		profile 'general:release'
		profile 'ios:release'
	end
end