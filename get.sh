#!/bin/bash

set -e

wget https://raw.githubusercontent.com/Parsiuk/minecraft-autoinstaller/refs/heads/master/part1.sh
wget https://raw.githubusercontent.com/Parsiuk/minecraft-autoinstaller/refs/heads/master/part2.sh
wget https://raw.githubusercontent.com/Parsiuk/minecraft-autoinstaller/refs/heads/master/part3.sh
chmod +x ./part*.sh

echo "Installation scripts downloaded. Please run them in order: ./part1.sh, then ./part2.sh, and finally ./part3.sh"
