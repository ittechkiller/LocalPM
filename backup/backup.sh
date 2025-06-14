#!/bin/bash

# === Configuration ===
PROJECT_ROOT="/home/tech/PM"
BACKUP_ROOT="$PROJECT_ROOT/backup"
DATA_DIR="$BACKUP_ROOT/data"
LOG_FILE="$BACKUP_ROOT/logs/backup.log"
SHARED_FOLDER="/home/shared/PM/backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$DATA_DIR/$TIMESTAMP"

# === Create directories ===
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_ROOT/logs"
mkdir -p "$SHARED_FOLDER"
chown tech:tech "$SHARED_FOLDER"

echo "[$(date)] Starting backup..." >> "$LOG_FILE"

# === Backup target folders ===
declare -A folders_to_backup=(
  ["gitea_data"]="$PROJECT_ROOT/gitea/data"
  ["kanboard_data"]="$PROJECT_ROOT/kanboard/data"
  ["woodpecker_data"]="$PROJECT_ROOT/woodpecker/data"
)

for name in "${!folders_to_backup[@]}"; do
  src="${folders_to_backup[$name]}"
  archive="$BACKUP_DIR/${name}.tar.gz"
  
  if [ -d "$src" ]; then
    tar -czf "$archive" -C "$src" . >> "$LOG_FILE" 2>&1
    echo "[$(date)] Backed up $src" >> "$LOG_FILE"
    
    # Copy to shared folder
    # cp "$archive" "$SHARED_FOLDER/" >> "$LOG_FILE" 2>&1
    # echo "[$(date)] Copied $archive to $SHARED_FOLDER" >> "$LOG_FILE"
    if [ -d "$SHARED_FOLDER" ]; then
      cp "$archive" "$SHARED_FOLDER" >> "$LOG_FILE" 2>&1
      echo "[$(date)] Copied backups to shared folder." >> "$LOG_FILE"
    else
      echo "[$(date)] ERROR: Shared folder path $SHARED_FOLDER not accessible." >> "$LOG_FILE"
    fi
    
  else
    echo "[$(date)] WARNING: $src not found" >> "$LOG_FILE"
  fi
done

# === Clean up backups older than 7 days ===
find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; >> "$LOG_FILE" 2>&1
echo "[$(date)] Cleanup complete. Backup finished." >> "$LOG_FILE"
