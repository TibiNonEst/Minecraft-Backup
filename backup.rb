#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'aws-sdk-s3'

json = File.read("#{__dir__}/config.json")
config = JSON.parse(json)
servers = config["servers"]

files = ""
puts "Starting backup"
puts "Starting copy"
system("mkdir #{__dir__}/temp")
servers.each do |server|
  system("mkdir #{__dir__}/temp/#{server}")
  files << " #{server}"
  if server == "bungee"
    system('screen -S bungee -p 0 -X stuff "lpb export luckperms^M"')
    system("sleep 2")
    system("cp #{__dir__}/bungee/plugins/LuckPerms/luckperms.json.gz #{__dir__}/temp/bungee/luckperms.json.gz")
    system("rm #{__dir__}/bungee/plugins/LuckPerms/luckperms.json.gz")
    system("cp #{__dir__}/bungee/config.yml #{__dir__}/temp/bungee/config.yml")
    system("cp #{__dir__}/bungee/plugins/ServerListPlus/ServerListPlus.yml #{__dir__}/temp/bungee/ServerListPlus.yml")
    system("cp #{__dir__}/bungee/plugins/BungeeSafeguard/config.yml #{__dir__}/temp/bungee/whitelist\\(BungeeSafeguard\\).yml")
  else
    system("cp -r #{__dir__}/#{server}/world /#{__dir__}/temp/#{server}/world")
    system("cp -r #{__dir__}/#{server}/server.properties #{__dir__}/temp/#{server}/server.properties")
    unless config.lobbies.include?server
      system("cp -r #{__dir__}/#{server}/world_nether #{__dir__}/temp/#{server}/world_nether")
      system("cp -r #{__dir__}/#{server}/world_the_end #{__dir__}/temp/#{server}/world_the_end")
    end
  end
  ls = `ls #{__dir__}/#{server}/plugins`
  plugins = ls.split(/\n/)
  jars = []
  plugins.each do |plugin|
    if plugin.include?".jar"
      jars.append(plugin)
    end
  end
  File.write("#{__dir__}/temp/#{server}/plugins.json", JSON.pretty_generate({:plugins => jars}))
end
puts "Finished copy"
puts "Starting zipping proccess"
system("rm #{__dir__}/backup.zip")
Dir.chdir("#{__dir__}/temp") do
  system("zip -r #{__dir__}/backup.zip#{files}")
end
system("rm -rf #{__dir__}/temp")
puts "Finished zipping proccess"
puts "Starting upload"

keys = config["keys"]

client = Aws::S3::Client.new(
  access_key_id: keys["access"],
  secret_access_key: keys["secret"],
  endpoint: "https://nyc3.digitaloceanspaces.com",
  region: "us-east-1"
)

File.open("#{__dir__}/backup.zip", "rb") do |file|
  client.put_object({
    bucket: "vorus-websites-cdn",
    key: "minecraft/backup.zip",
    body: file,
    acl: "public-read"
  })
end
puts "Upload done"
puts "Backup Complete!"
