# Minecraft Autoinstaller

## Purpose

A set of shell scripts that automate the installation of a Minecraft Java Edition server on Debian 13. Why Debian? This distribution is one of the oldest still maintained distributions. It is stable, predictable, and easy. I know there are plenty of derrivatives and they may have great features but those distros are coming and going and I couldn't possibly provide instructions and support for all of them.

The scripts handle everything from setting up `sudo` access, installing Docker and other required packages, to deploying a Minecraft server using the [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) Docker image.

## Prerequisites

- Clean Debian 13 installation. During installation pick "SSH server" and "standard system utilities".
- At least 2 GB of RAM (1 GB is reserved for the system, the rest is allocated to Minecraft).
- Root or sudo access (the installer will set up sudo if not already configured).

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

## What's next?

### Managing the server

Checking logs:
`docker logs minecraft_hostname`

Replace `hostname` with your server hostname. If unsure, use command `docker ps` and in the last column (NAMES) you will see your Minecraft servers name. Or just go with `minecraft_$(hostname)`. You can also use "autocompletion": just start typing container name and hit TAB on the keyboard. The name should be autopopulated.

Stopping the server:
`docker stop minecraft_hostname`

Starting:
`docker start minecraft_hostname`

If you made any changes to the docker-compose file, you have to go to the folder with that file and launch the stack with:
`docker compose up -d`

Checking how much disk space server files use:
`du -sh /srv/minecraft/`

### Issuing server commands

To list players currently in game:
`docker exec -i minecraft_hostname rcon-cli list`

Give yourself op:
`docker exec -i minecraft_hostname rcon-cli op YourName`

### Server backup

To backup the server first you must stop saving, save all data, and only then take a backup of your game folder. Typically this sequence would look like this:

```
user@hostname:~$ docker exec -i minecraft_hostname rcon-cli save-off
Automatic saving is now disabled

user@hostname:~$ docker exec -i minecraft_hostname rcon-cli save-all
Saving the game (this may take a moment!)Saved the game

user@hostname:~$ tar cvzf ~/backup.tar.gz /srv/minecraft/
(lots of lines here)

user@hostname:~$ docker exec -i minecraft_hostname rcon-cli save-on
Automatic saving is now enabled
```
