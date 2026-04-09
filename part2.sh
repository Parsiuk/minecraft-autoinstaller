#!/bin/bash

set -e

# Part 2: Docker-ce installation

echo "Removing old versions of Docker if they exist..."
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl bc -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install Docker Engine, containerd, and Docker Compose plugin:
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Enable Docker and containerd to start on boot:
sudo systemctl enable docker.service

# Start Docker:
sudo systemctl start docker

# Check if docker group exists
if ! getent group docker > /dev/null 2>&1; then
    sudo groupadd docker
fi

sudo usermod -aG docker $USER

echo "Docker installation complete. Launch part 3 of the installation script: ./part3.sh"

newgrp docker
