#!/bin/bash

printf "Nim should be installed before running the script.\nIf you still need to install it, CTRL+C out and install it.\n"
printf "5..."; sleep 1
printf "4..."; sleep 1
printf "3..."; sleep 1
printf "2..."; sleep 1
printf "1..."; sleep 1
echo "Starting..."

# Installing windows requirements, zip and python3 
sudo apt install -y mingw-w64 zip

# Installin nim requirements
nimble install crc32 nimpy
