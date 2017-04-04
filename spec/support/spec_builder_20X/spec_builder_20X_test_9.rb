spec('2.0.0') do
	configuration('debug') do
		profile 'general:debug'
		profile 'ios:debug'
		override 123, 345
		override nil, nil
		override true, {a: 123}
	end
end