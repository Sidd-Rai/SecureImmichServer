#!/bin/bash
set -eo pipefail
# stop-immich.sh
# Safely stop Immich Docker, then Nginx and WireGuard, only if no jobs are running.

# Colors
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BOLD="\e[1m"; RESET="\e[0m"

IMMICHMOUNTPOINT="YOUR_MOUNTPOINT"
DOCKER_DIR="YOUR_DOCKER_DIR"
IMMICH_URL="http://localhost:2283/api/jobs"
API_KEY="KEY"  # Replace with your Immich API key
WG_INTERFACE="INT1"  # change if your WireGuard interface name differs
MOUNTPOINT="YOUR_MOUNTPOINT"
MAPPER_NAME="immich_data"

# Ensure script is run with sudo/root
if [ "$EUID" -ne 0 ]; then
    echo -e "${BOLD}${RED}This script must be run with sudo/root. Aborting.${RESET}"
    exit 1
fi

# 0. Check if backup filesystem is mounted
if [ ! -d "$IMMICHMOUNTPOINT" ]; then
    echo -e "${BOLD}${RED}$IMMICHMOUNTPOINT does not exist. Please mount the backup filesystem first.${RESET}"
    exit 1
fi

# 0a. Check if Immich is already stopped
RUNNING=$(docker ps --filter "label=com.docker.compose.project=immich" --filter "status=running" -q)
if [ -z "$RUNNING" ]; then
    echo -e "${BOLD}${YELLOW}Immich is already stopped.${RESET}"
else
    # 1. Check Immich job queues
    echo -e "${BOLD}${YELLOW}Checking Immich job queues...${RESET}"
    JOBS_JSON=$(curl -s -H "x-api-key: $API_KEY" "$IMMICH_URL")

    ACTIVE_WAITING_QUEUES=$(echo "$JOBS_JSON" | jq -r '
      to_entries[] |
      select(.value.jobCounts.active > 0 or .value.jobCounts.waiting > 0) |
      "\(.key): active=\(.value.jobCounts.active), waiting=\(.value.jobCounts.waiting), paused=\(.value.jobCounts.paused)"')

    if [ -n "$ACTIVE_WAITING_QUEUES" ]; then
        echo -e "${BOLD}${RED}Immich has running or queued jobs in the following queues:${RESET}"
        echo -e "$ACTIVE_WAITING_QUEUES"
        echo -e "${BOLD}${RED}Aborting stop to prevent data corruption.${RESET}"
        exit 1
    fi

    echo -e "${BOLD}${GREEN}No active or waiting jobs detected. Safe to stop Immich.${RESET}"

    # 2. Stop Docker Compose
    echo -e "${BOLD}${YELLOW}Stopping Immich containers...${RESET}"
    cd "$DOCKER_DIR" || { echo -e "${RED}Failed to cd into $DOCKER_DIR${RESET}"; exit 1; }

    if ! docker compose down; then
        echo -e "${RED}Failed to stop Docker Compose${RESET}"
        exit 1
    fi

    # 3. Wait for all Immich containers to stop
    echo -e "${BOLD}${YELLOW}Waiting for Immich containers to fully stop...${RESET}"

    TIMEOUT=30
    ELAPSED=0
    while [ -n "$(docker ps --filter "label=com.docker.compose.project=immich" --filter "status=running" -q)" ]; do
        sleep 1
        ELAPSED=$((ELAPSED + 1))
        if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
            echo -e "${BOLD}${RED}Timeout reached: some Immich containers are still running.${RESET}"
            exit 1
        fi
    done

    echo -e "${BOLD}${GREEN}Immich stopped successfully.${RESET}"
fi

echo "Unmounting $MOUNTPOINT..."
sudo umount "$MOUNTPOINT" || { echo "Failed to unmount $MOUNTPOINT"; exit 1; }

echo "Closing LUKS device $MAPPER_NAME..."
sudo cryptsetup luksClose "$MAPPER_NAME" || { echo "Failed to close $MAPPER_NAME"; exit 1; }

echo "✅ Partition unmounted and locked."

