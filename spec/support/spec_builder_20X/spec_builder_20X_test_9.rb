spec('2.0.0') do
	configuration('debug') do
		override 123, 345
		override nil, nil
		override true, {a: 123}
	end
end