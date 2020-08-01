# The Cluster Backup Script
A script to backup [The Cluster](https://thecluster.xyz "The Cluster") Minecraft Network.

### What it does:
- Backup world files from enabled servers
- Create a JSON list of plugins for each server/proxy
- Backup server.properties for Spigot/Paper servers
- Backup config.yml for Bungeecord proxy
- Backup Luckperms data from Bungeecord proxy
- Backup BungeeSafeGuard whitelist and ServerListPlus config files from Bungeecord proxy
- Archive everything into a single zip file
- Upload the zip file to a DigitalOcean Space using AWS
