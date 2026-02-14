#!/bin/bash
set -eo pipefail

# Colors
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BOLD="\e[1m"; RESET="\e[0m"

IMMICHMOUNTPOINT="YOUR_MOUNTPOINT"
DOCKER_DIR="YOUR_DOCKER_DIRECTORY"
WG_INTERFACE="INT1"   # change if your WireGuard interface has a different name
DEVICE="/dev/sdax"  
CRYPT_NAME="immich_media_partition"   # name to use for the luks mapping
MOUNTPOINT="YOUR_MOUNTPOINT"

# 0. Ensure script is run with sudo/root
if [ "$EUID" -ne 0 ]; then
    echo -e "${BOLD}${RED}This script must be run with sudo/root. Aborting.${RESET}"
    exit 1
fi

# 1. Unlock LUKS if not already open
if [ ! -e "/dev/mapper/$CRYPT_NAME" ]; then
    echo "Unlocking LUKS device $DEVICE..."
    cryptsetup luksOpen "$DEVICE" "$CRYPT_NAME"
else
    echo "LUKS device $CRYPT_NAME already open."
fi

# 2. Mount filesystem
if ! mountpoint -q "$MOUNTPOINT"; then
    echo "Mounting /dev/mapper/$CRYPT_NAME at $MOUNTPOINT..."
    mount "/dev/mapper/$CRYPT_NAME" "$MOUNTPOINT"
    echo "Mounted successfully."
else
    echo "Already mounted at $MOUNTPOINT."
fi

# 3. Check if Immich is already running
RUNNING=$(docker ps --filter "label=com.docker.compose.project=immich" --filter "status=running" -q)
if [ -n "$RUNNING" ]; then
    echo -e "${BOLD}${YELLOW}Immich is already running. Aborting start.${RESET}"
    exit 0
fi

# 4. Check if backup filesystem is available
if [ ! -d "$IMMICHMOUNTPOINT" ]; then
    echo -e "${BOLD}${RED}$IMMICHMOUNTPOINT does not exist. Please mount the backup filesystem first.${RESET}"
    exit 1
fi

# 5. Start Immich
echo -e "${BOLD}${YELLOW}Starting Immich via Docker Compose...${RESET}"
cd "$DOCKER_DIR" || { echo -e "${RED}Failed to cd into $DOCKER_DIR${RESET}"; exit 1; }

if ! docker compose up -d; then
    echo -e "${RED}Failed to start Docker Compose${RESET}"
    exit 1
fi
sleep 3

# 6. Wait for Immich to be healthy
echo "Waiting for Immich server to become healthy..."
while [ "$(docker inspect -f '{{.State.Health.Status}}' immich_server)" != "healthy" ]; do
    sleep 2
done

# 7. Done
echo -e "${BOLD}${GREEN}Immich is running with WireGuard + Nginx!${RESET}"
echo "Local machine: http://localhost:2283"

