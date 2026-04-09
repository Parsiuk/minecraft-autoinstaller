#!/bin/bash

set -e

# Part 3: Create docker compose file

GID=$(id -g)
HOSTNAME=$(hostname)

# We want to set the maximum memory for Minecraft based on the system's total memory.
SYSTEM_MEMORY=$(free -h | awk '/^Mem:/ {print $2}' | sed 's/Gi//')
echo "System Memory: $SYSTEM_MEMORY"

# Stop script if SYSTEM_MEMORY is less than 2GB
if (( $(echo "$SYSTEM_MEMORY < 2" | bc -l) )); then
    echo "Error: System memory is less than 2GB. Minecraft may not run properly. Exiting."
    exit 1
fi

# We're reserving at least 1GB of memory for the system, so we subtract 1 from the total memory
# to get the maximum memory for Minecraft. We also drop everything after decimal point.
MINECRAFT_MEMORY=$(echo "$SYSTEM_MEMORY - 1" | bc | sed 's/\..*$//')

# Docker-compose file
mkdir -p ~/minecraft-docker-stack
cat > ~/minecraft-docker-stack/docker-compose.yml <<EOL
services:
  mc:
    image: itzg/minecraft-server
    container_name: "minecraft_${HOSTNAME}"
    ports:
      - 25565:25565
      - 25575:25575
    environment:
      EULA: "TRUE"
      INIT_MEMORY: "1G"
      MAX_MEMORY: "${MINECRAFT_MEMORY}G"
      TYPE: "VANILLA"
      VERSION: "1.21.11"
      UID: "${UID}"
      GID: "${GID}"
      LOG_TIMESTAMP: "true"
    env_file: .env
    tty: true
    stdin_open: true
    restart: unless-stopped
    volumes:
      # attach a directory relative to the directory containing this compose file
      - /srv/minecraft:/data
EOL

echo "Lets create RCON password for your Minecraft server (you can change this later in the .env file):"
echo -n "Enter RCON_PASSWORD: "
read -s RCON_PASSWORD
cat > ~/minecraft-docker-stack/.env <<EOL
RCON_PASSWORD=${RCON_PASSWORD}
EOL

echo "Docker-compose file created at ~/minecraft-docker-stack/docker-compose.yml"
cd ~/minecraft-docker-stack
docker compose up -d
echo "Minecraft server is starting up. You can check the logs with 'docker logs minecraft_${HOSTNAME}'"
