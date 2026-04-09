# Minecraft Autoinstaller

## Purpose

A set of shell scripts that automate the installation of a Minecraft Java Edition server on a Debian-based system. The scripts handle everything from setting up `sudo` access, installing Docker, to deploying a Minecraft server using the [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) Docker image.

## Prerequisites

- A Debian-based Linux system (e.g., Debian, Ubuntu)
- At least 2 GB of RAM (1 GB is reserved for the system, the rest is allocated to Minecraft)
- Root or sudo access (the installer will set up sudo if not already configured)
- Network access to download packages and Docker images

## What It Does

The installer is split into three parts due to group membership changes requiring a new shell session:

1. **part1.sh** — Ensures the current user has `sudo` access. If not, it installs `sudo` via `su` and adds the user to the `sudo` group.
2. **part2.sh** — Installs Docker CE from the official Docker repository, enables it on boot, and adds the user to the `docker` group.
3. **part3.sh** — Creates a `docker-compose.yml` at `~/minecraft-docker-stack/`, calculates memory allocation based on system RAM, prompts for an RCON password, and starts a Vanilla Minecraft 1.21.11 server.

## Usage

`wget -qO - https://raw.githubusercontent.com/Parsiuk/minecraft-autoinstaller/refs/heads/master/get.sh | bash`

Once all three parts are downloaded execute them in order:

`./part1.sh`

`./part2.sh`

`./part3.sh`

The script had to be split into three parts due to group membership changes. Each part ends with `newgrp` command which launches a new shell with the required group membership added.
