run do |spec, xcodeproj|
	xcodeproj.root_object.attributes['ConfigurationCount'] = spec.configurations.count
end