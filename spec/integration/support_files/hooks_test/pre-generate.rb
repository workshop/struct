run do |spec|
	spec.targets[0].configurations.each { |c|
		c.settings ||= {}
		c.settings['INFOPLIST_FILE'] = 'Info.plist'
	}
end