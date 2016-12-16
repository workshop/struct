#!/usr/bin/env ruby
require 'semantic'
require 'yaml'

content = File.read 'lib/version.rb'
ver_idx_s = content.index('\'')+1
ver_idx_e = content.rindex('\'')

old_version = Semantic::Version.new content[ver_idx_s...ver_idx_e]
new_version = Semantic::Version.new old_version.to_s # Clone the version number

if ARGV.length == 0 || ARGV[0] == 'patch'
	new_version.patch += 1
elsif ARGV[0] == 'minor'
	new_version.minor += 1
	new_version.patch = 0
elsif ARGV[0] == 'major'
	new_version.major += 1
	new_version.minor = 0
	new_version.patch = 0
end

content[ver_idx_s...ver_idx_e] = new_version.to_s
File.write 'lib/version.rb', content

load 'lib/version.rb'
puts "Updated gem version to #{Xcodegen::VERSION}"

changelog_content = YAML.load_file 'changelog.yml'
changelog_content['latest'] = Xcodegen::VERSION
File.write 'changelog.yml', changelog_content.to_yaml

unless changelog_content['versions'].key? Xcodegen::VERSION
	puts 'No changelog content available for this version, aborting.'
	puts `git reset --hard HEAD`
	exit -1
end

commit_message = "Version #{Xcodegen::VERSION}\n\n"
commit_message += changelog_content['versions'][Xcodegen::VERSION].map{ |str| " -  #{str}" }.join("\n")

puts `git add -A; git commit -m "#{commit_message}"`
puts `git tag #{Xcodegen::VERSION}`
puts `git push --follow-tags`