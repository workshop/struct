#!/usr/bin/env ruby
require 'semantic'
require 'json'
require 'yaml'
require 'excon'

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
puts "Updated gem version to #{StructCore::VERSION}"

changelog_content = YAML.load_file 'changelog.yml'
changelog_content['latest'] = StructCore::VERSION
File.write 'changelog.yml', changelog_content.to_yaml

unless changelog_content['versions'].key? StructCore::VERSION
	puts 'No changelog content available for this version, aborting.'
	puts `git reset --hard HEAD`
	exit -1
end

commit_message = "Version #{StructCore::VERSION}\n\n"
commit_message += changelog_content['versions'][StructCore::VERSION].map{ |str| " -  #{str}" }.join("\n")

puts `git add -A; git commit -m "#{commit_message}"`
puts `git tag #{StructCore::VERSION}`
puts `git push`
puts `git push origin #{StructCore::VERSION}`

return if ENV['GITHUB_API_KEY'] == nil

begin
puts Excon.post('https://api.github.com/repos/workshop/struct/releases',
	:connect_timeout => 30,
	:body => {
		:tag_name => StructCore::VERSION,
		:name => "Version #{StructCore::VERSION}",
		:body => changelog_content['versions'][StructCore::VERSION].map{ |str| " -  #{str}" }.join("\n")
	}.to_json,
	:headers => {
		'Content-Type' => 'application/json',
		'Authorization' => "Bearer #{ENV['GITHUB_API_KEY']}",
		'User-Agent' => 'struct releaser'
	}
).body
rescue StandardError => err
	puts err
end