#!/bin/bash

# Set bash flags to stop script on error
set -e

# Part 1: Check if user is in sudo group
if groups "$(whoami)" | grep -q "\bsudo\b"; then
    echo "User is in the sudo group. Continuing with installation..."
else
    echo "User is not in the sudo group. Installing sudo and adding user to sudo group..."

    # Execute `apt install sudo` as root using `su` command
    echo "Provide root password when prompted to install sudo:"
    su - -c "apt update && apt install -y sudo"

    # Add the current user to the sudo group
    current_user=$(whoami)
    echo "Adding user '$current_user' to the sudo group. Provide root password when prompted:"
    su - -c "usermod -aG sudo $current_user"
    echo "User '$current_user' has been added to the sudo group. At this stage you can test sudo access and install ant other packages which you may need."
    echo "Lanuch part 2 of the installation script to continue: ./part2.sh"
    newgrp sudo
fi
