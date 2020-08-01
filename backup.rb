#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'aws-sdk-s3'

servers = ["bungee", "corona", "faf", "lobby", "plot", "testing"]
files = ""
puts "Starting backup"
puts "Starting copy"
system("mkdir /var/minecraft/temp")
servers.each do |server|
	system("mkdir /var/minecraft/temp/#{server}")
	files << " #{server}"
	if server == "bungee"
		system('screen -S bungee -p 0 -X stuff "lpb export luckperms^M"')
    system('sleep 1')
    system("cp /var/minecraft/bungee/plugins/LuckPerms/luckperms.json.gz /var/minecraft/temp/bungee/luckperms.json.gz")
    system("rm /var/minecraft/bungee/plugins/LuckPerms/luckperms.json.gz")
		system("cp /var/minecraft/bungee/config.yml /var/minecraft/temp/bungee/config.yml")
		system("cp /var/minecraft/bungee/plugins/ServerListPlus/ServerListPlus.yml /var/minecraft/temp/bungee/ServerListPlus.yml")
		system("cp /var/minecraft/bungee/plugins/BungeeSafeguard/config.yml /var/minecraft/temp/bungee/whitelist\\(BungeeSafeguard\\).yml")
	else
		system("cp -r /var/minecraft/#{server}/world /var/minecraft/temp/#{server}/world")
		system("cp -r /var/minecraft/#{server}/server.properties /var/minecraft/temp/#{server}/server.properties")
		unless server == "lobby"
			system("cp -r /var/minecraft/#{server}/world_nether /var/minecraft/temp/#{server}/world_nether")
			system("cp -r /var/minecraft/#{server}/world_the_end /var/minecraft/temp/#{server}/world_the_end")
		end
	end
	ls = `ls /var/minecraft/#{server}/plugins`
	plugins = ls.split(/\n/)
	jars = []
	plugins.each do |plugin|
		if plugin.include?".jar"
			jars.append(plugin)
		end
	end
	File.write("/var/minecraft/temp/#{server}/plugins.json", JSON.pretty_generate({:plugins => jars}))
end
puts "Finished copy"
puts "Starting zipping proccess"
system("rm /var/minecraft/backup.zip")
Dir.chdir("/var/minecraft/temp") do
	system("zip -r /var/minecraft/backup.zip#{files}")
end
system("rm -rf /var/minecraft/temp")
puts "Finished zipping proccess"
puts "Starting upload"

json = File.read('/var/minecraft/api-keys.json')
obj = JSON.parse(json)

client = Aws::S3::Client.new(
	access_key_id: obj["access"],
	secret_access_key: obj["secret"],
	endpoint: 'https://nyc3.digitaloceanspaces.com',
	region: 'us-east-1'
)

File.open('/var/minecraft/backup.zip', 'rb') do |file|
	client.put_object({
		bucket: "vorus-websites-cdn",
		key: "minecraft/backup.zip",
		body: file,
		acl: "public-read"
	})
end
puts "Upload done"
puts "Backup Complete!"