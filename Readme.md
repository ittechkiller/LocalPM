# 🛠️ Local DevOps Project Management Stack

This repository provides a **fully offline**, self-hosted project management and CI/CD environment for small to medium teams (5–10 members) using Docker Compose.

## 📦 Services Included

| Service          | Description                               | Access URL            |
|------------------|-------------------------------------------|------------------------|
| **Gitea**         | Lightweight Git hosting with SSH(2222)   | http://gitea.local     |
| **Kanboard**      | Simple and effective project board        | http://kanboard.local  |
| **Woodpecker CI** | Modern lightweight CI/CD server           | http://ci.local        |
| **NGINX**         | Reverse proxy for local domain routing    | localhost (port 80)    |

## 🚀 Getting Started

### 1. Clone This Repository

```
git clone https://your.repo.url
cd your-project-folder
```
📁 Folder Structure
bash
Copy
Edit
.
├── docker-compose.yml
├── nginx/
│   └── nginx.conf
├── gitea/
│   └── data/                # Gitea config and repositories
├── kanboard/
│   └── data/                # Kanboard config and tasks
├── woodpecker/
│   └── data/                # Woodpecker build data
All volumes are mounted locally for persistence and backup.


#### 🧱Docker Compose Service Configuration
Gitea
Web UI: http://gitea.local

SSH Git Port: 2222

Data volume: ./gitea/data

Woodpecker CI
Web UI: http://ci.local

Configured to use Gitea OAuth

SQLite for simple local setup

Kanboard
Web UI: http://kanboard.local

Data volume: ./kanboard/data

NGINX
Routes *.local domains to internal services

Uses simple reverse proxy configuration

### 2. Adjust Your /etc/hosts
Add the following lines to your /etc/hosts file (on host machine and any guest VMs):
```
127.0.0.1 gitea.local
127.0.0.1 kanboard.local
127.0.0.1 ci.local
```
And add following lines to your team members pc(LAN)'s /etc/hosts
```
your-host-os-ip gitea.local ## the host machine’s LAN IP or VMware NAT IP
your-host-os-ip kanboard.local
your-host-os-ip ci.local
```

#### VMware/Network consideration
Make sure VMware network mode is Bridged or NAT with port forwarding to the host.
If NAT, forward port 80 (and optionally 3000, 2222 for direct Gitea access) from the VMware NAT interface to your host machine.
Example port forwarding rules for VMware NAT:

Guest   Host 	Service
80	    8080	Nginx
3000	3000	Gitea HTTP
2222	2222	Gitea SSH

### 3. Running the Stack
```
docker-compose up -d
```
All services will be available through NGINX at the local domains.

🔧 Useful Commands
Stop all services (without removing)
```
docker-compose stop
```
Start all services again
```
docker-compose start
```
View logs
```
docker-compose logs -f
```
Shutdown and remove containers (data persists)
```
docker-compose down
```

🐙 Git over SSH
Gitea exposes SSH on port 2222 (host side):
```
git clone ssh://git@gitea.local:2222/your-user/your-repo.git
```

📌 Notes
Works entirely offline, no internet required.

Suitable for air-gapped or LAN-only environments.

All services communicate internally via Docker networks.

Ensure Docker and Docker Compose are installed.

# Docker and Docker Compose install
Step 1: Check Your Ubuntu Version
```
lsb_release -a
```
🧽 Step 2: Clean Existing Docker Sources
To avoid conflicts, clean old Docker sources:
```
sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.gpg
```
🔁 Step 3: Re-add the Docker Repository (Cleanly)
##### Install required tools
```
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
```
##### Add Docker's GPG key
```
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```
Now add the Docker repo:
```
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
🔄 Step 4: Update APT and Install Docker
```
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugi
```
# Register Docker Compose as a systemd Service
### 1. Create a systemd service file
```
sudo nano /etc/systemd/system/devstack.service
```
Paste the following content:
```
[Unit]
Description=Local DevOps Stack (Gitea, Kanboard, Woodpecker, NGINX)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/path/to/your/project
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```
Replace /path/to/your/project with your actual path:
### 2. Reload systemd
```
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
```
### 3.  Enable the service to run at boot
```
sudo systemctl enable devstack.service
```
### 4. Start the service manually (first time)
```
sudo systemctl start devstack.service
```
## 🔍 Useful Commands
##### Check service status:
```
sudo systemctl status devstack.service
```
##### Stop the service:
```
sudo systemctl stop devstack.service
```
##### Disable from boot:
```
sudo systemctl disable devstack.service
```

## Backup
#### ✅ Final backup.sh (directly archive mounted volumes)
Save this script as:
/home/tech/PM/backup/backup.sh
```
#!/bin/bash

# === Configuration ===
PROJECT_ROOT="/home/tech/PM"
BACKUP_ROOT="$PROJECT_ROOT/backup"
DATA_DIR="$BACKUP_ROOT/data"
LOG_FILE="$BACKUP_ROOT/logs/backup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$DATA_DIR/$TIMESTAMP"

# === Create directories ===
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_ROOT/logs"

echo "[$(date)] Starting backup..." >> "$LOG_FILE"

# === Backup target folders ===
declare -A folders_to_backup=(
  ["gitea_data"]="$PROJECT_ROOT/gitea/data"
  ["kanboard_data"]="$PROJECT_ROOT/kanboard/data"
  ["woodpecker_data"]="$PROJECT_ROOT/woodpecker/data"
)

for name in "${!folders_to_backup[@]}"; do
  src="${folders_to_backup[$name]}"
  if [ -d "$src" ]; then
    tar -czf "$BACKUP_DIR/${name}.tar.gz" -C "$src" . >> "$LOG_FILE" 2>&1
    echo "[$(date)] Backed up $src" >> "$LOG_FILE"
  else
    echo "[$(date)] WARNING: $src not found" >> "$LOG_FILE"
  fi
done

# === Clean up backups older than 7 days ===
find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; >> "$LOG_FILE" 2>&1
echo "[$(date)] Cleanup complete. Backup finished." >> "$LOG_FILE"
```
#### ✅ Make the script executable
```
chmod +x /home/tech/PM/backup/backup.sh
```
#### ✅ Set up Cron Job (run hourly)
```
crontab -e
```
Add this line to run it every hour:
```
0 * * * * /home/tech/PM/backup/backup.sh >> /home/tech/PM/backup/logs/cron.log 2>&1
```
