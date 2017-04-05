spec('2.0.0') do
	pre_generate do |spec|
		puts spec
	end
	post_generate do |spec, xcodeproj|
		puts spec
		puts xcodeproj
	end
	configuration('my-configuration') do
		profile 'general:debug'
		profile 'ios:debug'
		type 'debug'
	end
	target('my-target') do
		type :application
		source_dir 'support_files/abc'
		configuration do end
	end
end