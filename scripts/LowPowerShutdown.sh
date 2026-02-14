#!/bin/bash
# Ensure full PATH for cron
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

MOUNTPOINT="YOUR_MOUNTPOINT"
MAPPER_NAME="immich_media_partition"
DOCKER_DIR="YOUR_DOCKER_DIRECTORY"
LOGFILE="/home/username/battery.log"

# 1. Check battery
BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT1/capacity) #might differ for your PC
if [ "$BATTERY_LEVEL" -ge 30 ]; then
echo "$(date) - Battery Fine ($BATTERY_LEVEL%), doing nothing..." >> "$LOGFILE"
    exit 0
fi

echo "$(date) - Battery low ($BATTERY_LEVEL%), stopping Immich..." >> "$LOGFILE"

# 2. Stop Docker Compose
cd "$DOCKER_DIR" || { echo "$(date) - Failed to cd into $DOCKER_DIR" >> "$LOGFILE"; exit 1; }
docker compose down >> "$LOGFILE" 2>&1 || { echo "$(date) - Docker Compose failed" >> "$LOGFILE"; exit 1; }

# 3. Wait for all Immich containers to stop
TIMEOUT=30
ELAPSED=0
while [ -n "$(docker ps --filter "label=com.docker.compose.project=immich" --filter "status=running" -q)" ]; do
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "$(date) - Timeout reached: some containers still running" >> "$LOGFILE"
        exit 1
    fi
done
echo "$(date) - Immich stopped successfully" >> "$LOGFILE"

# 4. Unmount and lock LUKS
umount "$MOUNTPOINT" >> "$LOGFILE" 2>&1 || { echo "$(date) - Failed to unmount $MOUNTPOINT" >> "$LOGFILE"; exit 1; }
cryptsetup luksClose "$MAPPER_NAME" >> "$LOGFILE" 2>&1 || { echo "$(date) - Failed to close $MAPPER_NAME" >> "$LOGFILE"; exit 1; }

echo "$(date) - Partition unmounted and locked" >> "$LOGFILE"

# 5. Shutdown
shutdown
