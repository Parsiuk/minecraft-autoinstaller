# Manual Installation Guide

This document explains each step performed by the automated installation scripts (`part1.sh`, `part2.sh`, `part3.sh`). Follow these instructions if you want to understand or manually replicate what the scripts do.

---

## Part 1: Ensure sudo access (`part1.sh`)

This script makes sure your user account has `sudo` privileges, which are required for the rest of the installation.

1. **Check if the current user is in the `sudo` group.**
   The script runs `groups` to see if your user already belongs to the `sudo` group.
   ```bash
   groups "$(whoami)" | grep -q "\bsudo\b"
   ```

2. **If the user already has sudo access** — skip ahead to Part 2.

3. **If the user does NOT have sudo access:**
   - **Install `sudo`** — You will be prompted for the **root** password. The script runs `su` to become root and executes `apt update && apt install -y sudo`.
     ```bash
     su - -c "apt update && apt install -y sudo"
     ```
   - **Add your user to the `sudo` group** — Again using `su` with the root password, the script runs `usermod -aG sudo <your_username>`.
     ```bash
     su - -c "usermod -aG sudo $current_user"
     ```
   - **Apply the new group membership** — The script calls `newgrp sudo` so the group change takes effect in the current session without needing to log out and back in.
     ```bash
     newgrp sudo
     ```

After this part completes, your user can run commands with `sudo`. Proceed to Part 2.

---

## Part 2: Install Docker (`part2.sh`)

This script installs Docker Engine from Docker's official Debian repository and runs a quick CPU performance benchmark.

1. **Remove old Docker packages** — Uninstalls any previously installed `docker.io`, `docker-compose`, `docker-doc`, `podman-docker`, `containerd`, and `runc` packages to avoid conflicts.
   ```bash
   sudo apt remove "$(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)"
   ```

2. **Install prerequisite packages** — Runs `apt update` and installs `ca-certificates`, `curl`, `bc`, and `sysbench`.
   ```bash
   sudo apt update
   sudo apt install ca-certificates curl bc sysbench -y
   ```

3. **Add Docker's official GPG key** — Downloads Docker's GPG signing key to `/etc/apt/keyrings/docker.asc` and makes it world-readable. This allows APT to verify the authenticity of packages from Docker's repository.
   ```bash
   sudo install -m 0755 -d /etc/apt/keyrings
   sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
   sudo chmod a+r /etc/apt/keyrings/docker.asc
   ```

4. **Add the Docker APT repository** — Creates a new APT source file at `/etc/apt/sources.list.d/docker.sources` pointing to `https://download.docker.com/linux/debian`, configured for your Debian release codename and CPU architecture.
   ```bash
   sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
   Types: deb
   URIs: https://download.docker.com/linux/debian
   Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
   Components: stable
   Architectures: $(dpkg --print-architecture)
   Signed-By: /etc/apt/keyrings/docker.asc
   EOF
   ```

5. **Install Docker Engine** — Runs `apt update` again (to pick up the new repository) and installs:
   - `docker-ce` (Docker Engine)
   - `docker-ce-cli` (Docker command-line tool)
   - `containerd.io` (container runtime)
   - `docker-buildx-plugin` (build extension)
   - `docker-compose-plugin` (Compose v2)
   ```bash
   sudo apt update
   sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
   ```

6. **Enable and start Docker** — Enables the Docker service to start automatically on boot and starts it immediately.
   ```bash
   sudo systemctl enable docker.service
   sudo systemctl start docker
   ```

7. **Add your user to the `docker` group** — Creates the `docker` group if it doesn't exist, then adds your user to it. This allows you to run `docker` commands without `sudo`.
   ```bash
   if ! getent group docker > /dev/null 2>&1; then
       sudo groupadd docker
   fi
   sudo usermod -aG docker "${USER}"
   ```

8. **Run a CPU performance benchmark** — Executes `sysbench cpu --threads=1 run` and checks the result:
   - If the score is **below 20,000**, a warning is displayed that the server may experience performance issues.
   - If the score is **20,000 or above**, a confirmation message is shown.
   ```bash
   BENCHMARK_RESULT=$(sysbench cpu --threads=1 run | grep 'total number of events' | awk '{print $5}')
   ```

9. **Apply the new group membership** — Calls `newgrp docker` so you can use Docker immediately without logging out.
   ```bash
   newgrp docker
   ```

After this part completes, Docker is installed and ready. Proceed to Part 3.

---

## Part 3: Create and launch the Minecraft server (`part3.sh`)

This script generates a Docker Compose configuration for a Minecraft server and starts it.

1. **Detect system memory** — Reads the total system RAM (in GB) using the `free` command.
   ```bash
   SYSTEM_MEMORY=$(free -h | awk '/^Mem:/ {print $2}' | sed 's/Gi//')
   ```

2. **Validate minimum memory** — If the system has less than **2 GB** of RAM, the script exits with an error because Minecraft requires more memory to run properly.
   ```bash
   if (( $(echo "$SYSTEM_MEMORY < 2" | bc -l) )); then
       echo "Error: System memory is less than 2GB. Minecraft may not run properly. Exiting."
       exit 1
   fi
   ```

3. **Calculate Minecraft memory allocation** — Subtracts 1 GB from the total system memory (reserved for the OS) and uses the remainder as the maximum heap size for the Minecraft server. The initial heap is set to 1 GB.
   ```bash
   MINECRAFT_MEMORY=$(echo "$SYSTEM_MEMORY - 1" | bc | sed 's/\..*$//')
   ```

4. **Create the Docker Compose file** — Creates the directory `~/minecraft-docker-stack/` and writes a `docker-compose.yml` file with the following configuration:
   - **Image:** `itzg/minecraft-server` (a popular community Docker image for Minecraft servers)
   - **Ports:**
     - `25565` — Minecraft game port
     - `25575` — RCON (remote console) port
   - **Environment variables:**
     - `EULA: TRUE` — Accepts the Minecraft EULA
     - `INIT_MEMORY` / `MAX_MEMORY` — Java heap size (1 GB initial, auto-calculated max)
     - `TYPE: VANILLA` — Vanilla Minecraft server (no mods)
     - `VERSION: 1.21.11` — Minecraft version to install
     - `UID` / `GID` — Runs the server process as your user/group
     - `LOG_TIMESTAMP: true` — Adds timestamps to log output
   - **Volumes:** Mounts `/srv/minecraft` on the host to `/data` in the container (this is where world data, configs, and plugins are stored)
   - **Restart policy:** `unless-stopped` — The container restarts automatically unless you explicitly stop it
   ```bash
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
         - /srv/minecraft:/data
   EOL
   ```

5. **Set the RCON password** — Prompts you to enter an RCON password (typed input is hidden). The password is saved to `~/minecraft-docker-stack/.env`, which the Compose file references via `env_file`.
   ```bash
   echo -n "Enter RCON_PASSWORD: "
   read -r -s RCON_PASSWORD
   cat > ~/minecraft-docker-stack/.env <<EOL
   RCON_PASSWORD=${RCON_PASSWORD}
   EOL
   ```

6. **Start the Minecraft server** — Runs `docker compose up -d` to launch the container in the background.
   ```bash
   cd ~/minecraft-docker-stack
   docker compose up -d
   ```

7. **Verify** — After launch, you can check the server logs with:
   ```bash
   docker logs minecraft_<your_hostname>
   ```

---

## Summary

| Step | Script | What it does |
|------|--------|--------------|
| 1 | `part1.sh` | Ensures your user has `sudo` access |
| 2 | `part2.sh` | Installs Docker Engine and runs a performance check |
| 3 | `part3.sh` | Creates a Dockerized Minecraft server and starts it |
