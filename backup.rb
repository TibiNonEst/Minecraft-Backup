#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'aws-sdk-s3'

json = File.read("#{__dir__}/config.json")
config = JSON.parse(json)
servers = config["servers"] + config["proxies"] + config["lobbies"]
servers - (config["servers"] & config["proxies"])
servers - (config["servers"] & config["lobbies"])
servers - (config["proxies"] & config["lobbies"])

files = ""
puts "Starting backup"
puts "Starting copy"

system("mkdir #{__dir__}/temp")
servers.each do |server|
  system("mkdir #{__dir__}/temp/#{server}")
  files << " #{server}"
  system("cp -r #{__dir__}/#{server}/logs /#{__dir__}/temp/#{server}/logs")
  if config["proxies"].include?server
    system("screen -S #{server} -p 0 -X stuff \"lpb export luckperms^M\"")
    system("sleep 2")
    system("cp #{__dir__}/#{server}/plugins/LuckPerms/luckperms.json.gz #{__dir__}/temp/#{server}/luckperms.json.gz")
    system("rm #{__dir__}/#{server}/plugins/LuckPerms/luckperms.json.gz")
    system("cp #{__dir__}/#{server}/config.yml #{__dir__}/temp/#{server}/config.yml")
    system("cp #{__dir__}/#{server}/plugins/ServerListPlus/ServerListPlus.yml #{__dir__}/temp/#{server}/ServerListPlus.yml")
    system("cp #{__dir__}/#{server}/plugins/BungeeSafeguard/config.yml #{__dir__}/temp/#{server}/whitelist\\(BungeeSafeguard\\).yml")
  else
    system("cp -r #{__dir__}/#{server}/world /#{__dir__}/temp/#{server}/world")
    system("cp -r #{__dir__}/#{server}/server.properties #{__dir__}/temp/#{server}/server.properties")
    unless config["lobbies"].include?server
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
  File.write("#{__dir__}/temp/#{server}/plugins.json", JSON.pretty_generate(jars)
end
puts "Finished copy"
File.delete("#{__dir__}/backup.zip") if File.exist?("#{__dir__}/backup.zip")
puts "Starting zipping proccess"
Dir.chdir("#{__dir__}/temp") do
  system("zip -r #{__dir__}/backup.zip#{files}")
end
system("rm -rf #{__dir__}/temp")
puts "Finished zipping proccess"
puts "Starting upload"

keys = config["keys"]
s3config = config["s3"]
s3 = Aws::S3::Resource.new(region: s3config["region"], endpoint: s3config["endpoint"], access_key_id: keys["access"], secret_access_key: keys["secret"])
obj = s3.bucket(s3config["bucket"]).object(s3config["object"])
obj.upload_file("#{__dir__}/backup.zip")

puts "Upload done"
File.delete("#{__dir__}/backup.zip")
puts "Backup Complete!"
