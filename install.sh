#!/bin/bash

REPO_URL="https://github.com/power0matin/kuma-monitoring-reporter.git"
INSTALL_DIR="$HOME/kuma-monitoring-reporter"
CONFIG_FILE="$INSTALL_DIR/config/config.json"
SYSTEMD_SERVICE="/etc/systemd/system/kuma-reporter.service"
BACKUP_DIR="/tmp/kuma-backup"
LOG_FILE="$INSTALL_DIR/logs/error.log"

# چک کردن پیش‌نیازها
command -v git >/dev/null 2>&1 || { echo "Git is not installed. Please install Git."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Python3 is not installed."; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "pip3 is not installed."; exit 1; }
command -v systemctl >/dev/null 2>&1 || { echo "Systemd is not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is not installed. Please install jq for Telegram testing."; exit 1; }

function install_project() {
  echo "Installing kuma-monitoring-reporter project ..."

  if [ -d "$INSTALL_DIR" ]; then
    echo "Directory already exists: $INSTALL_DIR"
    echo "Please use 'Update project' (option 3) or remove the directory first."
    return 1
  fi

  mkdir -p "$(dirname "$INSTALL_DIR")" || { echo "Failed to create parent directory."; exit 1; }

  echo "Cloning repository from $REPO_URL..."
  git clone "$REPO_URL" "$INSTALL_DIR" || {
    echo "Failed to clone repository. Check network or repository URL."
    exit 1
  }

  cd "$INSTALL_DIR" || { echo "Failed to change directory to $INSTALL_DIR"; exit 1; }
  echo "Creating virtual environment..."
  python3 -m venv venv || { echo "Failed to create virtual environment."; exit 1; }
  source venv/bin/activate
  echo "Installing dependencies..."
  pip install -r requirements.txt || { echo "Failed to install dependencies."; deactivate; exit 1; }
  deactivate

  echo "Installation completed successfully."
  echo "First run: source $INSTALL_DIR/venv/bin/activate; python3 report.py"
}

function update_project() {
  echo "Updating kuma-monitoring-reporter project ..."

  if [ ! -d "$INSTALL_DIR" ]; then
    echo "Project directory does not exist: $INSTALL_DIR"
    echo "Please install the project first using option 1."
    exit 1
  fi

  cd "$INSTALL_DIR" || { echo "Failed to change directory to $INSTALL_DIR"; exit 1; }
  echo "Pulling latest changes from repository..."
  git pull origin main || {
    echo "Failed to update repository. Check network or repository status."
    exit 1
  }

  echo "Updating dependencies..."
  source venv/bin/activate
  pip install -r requirements.txt || { echo "Failed to install dependencies."; deactivate; exit 1; }
  deactivate

  echo "Project updated successfully."
  echo "Run the project: source $INSTALL_DIR/venv/bin/activate; python3 report.py"
}

function edit_config() {
  echo "Configuring config.json file..."

  mkdir -p "$(dirname "$CONFIG_FILE")" || { echo "Failed to create config directory."; exit 1; }

  read -p "🌐 Kuma Metrics URL (e.g. http://localhost:3001/metrics): " kuma_url
  read -p "🤖 Telegram bot token: " telegram_bot_token
  read -p "💬 Telegram chat ID (e.g. 123456789): " telegram_chat_id
  read -p "🔑 API token for Kuma (leave empty if not needed): " auth_token
  read -p "🟢 Good threshold (ms, e.g. 200): " good
  read -p "🟡 Warning threshold (ms, e.g. 500): " warning
  read -p "🔴 Critical threshold (ms, e.g. 1000): " critical
  read -p "⏰ Report interval (minutes, e.g. 1 for every minute): " report_interval
  read -p "🔔 Notification mode (sound/silent): " notification_mode

  if ! [[ "$report_interval" =~ ^[0-9]+$ ]] || [ "$report_interval" -lt 1 ]; then
    echo "Report interval must be a positive integer."
    exit 1
  fi

  if [[ "$notification_mode" != "sound" && "$notification_mode" != "silent" ]]; then
    echo "Notification mode must be 'sound' or 'silent'."
    exit 1
  fi

  cat > "$CONFIG_FILE" <<EOF
{
  "kuma_url": "$kuma_url",
  "telegram_bot_token": "$telegram_bot_token",
  "telegram_chat_id": "$telegram_chat_id",
  "auth_token": "$auth_token",
  "thresholds": {
    "good": $good,
    "warning": $warning,
    "critical": $critical
  },
  "report_interval": $report_interval,
  "notification_mode": "$notification_mode"
}
EOF

  echo "Configuration saved successfully: $CONFIG_FILE"
}

function setup_systemd() {
  echo "Setting up systemd service for kuma-monitoring-reporter ..."

  if [ -f "$SYSTEMD_SERVICE" ]; then
    echo "Systemd service already exists: $SYSTEMD_SERVICE"
    read -p "Do you want to overwrite it? (y/n): " overwrite
    if [[ "$overwrite" != "y" ]]; then
      echo "Operation canceled."
      return 1
    fi
  fi

  cat > "$SYSTEMD_SERVICE" <<EOF
[Unit]
Description=Kuma Monitoring Reporter Service
After=network.target

[Service]
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python3 $INSTALL_DIR/report.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload || { echo "Failed to reload systemd daemon."; exit 1; }
  systemctl enable kuma-reporter.service || { echo "Failed to enable systemd service."; exit 1; }
  systemctl start kuma-reporter.service || { echo "Failed to start systemd service."; exit 1; }

  echo "Systemd service setup successfully."
  echo "Check status: systemctl status kuma-reporter.service"
}

function stop_bot() {
  echo "Stopping kuma-monitoring-reporter bot ..."

  if [ -f "$SYSTEMD_SERVICE" ]; then
    systemctl stop kuma-reporter.service 2>/dev/null && echo "Systemd service stopped."
    read -p "Do you want to disable the service? (y/n): " disable
    if [[ "$disable" == "y" ]]; then
      systemctl disable kuma-reporter.service 2>/dev/null && echo "Systemd service disabled."
    fi
  else
    echo "No systemd service found. Checking for running processes ..."
    pids=$(pgrep -f "python3 $INSTALL_DIR/report.py")
    if [ -n "$pids" ]; then
      echo "Found running bot processes (PIDs: $pids)."
      read -p "Do you want to terminate them? (y/n): " confirm
      if [[ "$confirm" == "y" ]]; then
        kill $pids && echo "Bot processes terminated."
      else
        echo "Operation canceled."
      fi
    else
      echo "No running bot processes found."
    fi
  fi

  echo "Bot stop operation completed."
}

function test_telegram() {
  echo "Testing Telegram configuration ..."

  if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found: $CONFIG_FILE"
    echo "Please configure the project first using option 2."
    exit 1
  fi

  cd "$INSTALL_DIR" || { echo "Failed to change directory to $INSTALL_DIR"; exit 1; }
  source venv/bin/activate

  python3 - <<EOF
from core.telegram import test_telegram_notification
result = test_telegram_notification()
if result['status'] == 'success':
    print(f"Test message sent successfully. Silent mode: {result['silent']}")
else:
    print(f"Failed to send test message: {result['error']}")
EOF

  deactivate
}

function backup_logs() {
  echo "Backing up logs ..."

  if [ ! -f "$LOG_FILE" ]; then
    echo "No log file found: $LOG_FILE"
    return 1
  fi

  mkdir -p "$BACKUP_DIR" || { echo "Failed to create backup directory."; exit 1; }
  timestamp=$(date +%Y%m%d_%H%M%S)
  backup_file="$BACKUP_DIR/logs_$timestamp.tar.gz"

  tar -czf "$backup_file" "$LOG_FILE" || { echo "Failed to create backup."; exit 1; }
  echo "Logs backed up successfully to $backup_file."
}

function show_status() {
  echo "Project status for kuma-monitoring-reporter ..."

  echo "Directory: $INSTALL_DIR"
  if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR" || { echo "Failed to access directory."; exit 1; }
    echo "Git version: $(git rev-parse --short HEAD 2>/dev/null || echo 'Not a git repository')"
  else
    echo "Project not installed."
  fi

  echo "Config file: $CONFIG_FILE"
  if [ -f "$CONFIG_FILE" ]; then
    echo "Configuration:"
    jq '.' "$CONFIG_FILE"
  else
    echo "Config file not found."
  fi

  echo "Systemd service: $SYSTEMD_SERVICE"
  if [ -f "$SYSTEMD_SERVICE" ]; then
    systemctl status kuma-reporter.service --no-pager
  else
    echo "Systemd service not setup."
  fi

  echo "Running processes:"
  pgrep -f "python3 $INSTALL_DIR/report.py" && echo "Bot is running." || echo "No bot processes found."
}

function restart_service() {
  echo "Restarting kuma-monitoring-reporter service ..."

  if [ -f "$SYSTEMD_SERVICE" ]; then
    systemctl restart kuma-reporter.service || { echo "Failed to restart systemd service."; exit 1; }
    echo "Systemd service restarted successfully."
    echo "Check status: systemctl status kuma-reporter.service"
  else
    echo "No systemd service found. Please setup the service using option 4.1."
  fi
}

function check_dependencies() {
  echo "Checking dependencies ..."

  if [ ! -d "$INSTALL_DIR" ]; then
    echo "Project directory does not exist: $INSTALL_DIR"
    exit 1
  fi

  cd "$INSTALL_DIR" || { echo "Failed to change directory to $INSTALL_DIR"; exit 1; }
  source venv/bin/activate
  pip install -r requirements.txt || { echo "Failed to install dependencies."; deactivate; exit 1; }
  deactivate

  echo "All dependencies are installed."
}

function uninstall_project() {
  echo "This will delete the entire project!"
  read -p "Do you want to keep config.json? (y/n): " keep_config
  read -p "Are you sure you want to delete the project? (y/n): " confirm

  if [[ "$confirm" == "y" ]]; then
    if [[ "$keep_config" == "y" ]]; then
      mkdir -p "$BACKUP_DIR"
      cp "$CONFIG_FILE" "$BACKUP_DIR/config.json" 2>/dev/null && echo "config.json backed up to $BACKUP_DIR/config.json"
      rm -rf "$INSTALL_DIR"
      echo "Project deleted, config.json preserved in $BACKUP_DIR/config.json."
    else
      rm -rf "$INSTALL_DIR"
      echo "Project and config.json deleted."
    fi

    if [ -f "$SYSTEMD_SERVICE" ]; then
      systemctl stop kuma-reporter.service 2>/dev/null
      systemctl disable kuma-reporter.service 2>/dev/null
      rm -f "$SYSTEMD_SERVICE"
      systemctl daemon-reload
      echo "Systemd service removed."
    fi
  else
    echo "Operation canceled."
  fi
}

function service_management_menu() {
  clear
  echo "Service Management Menu"
  echo "-------------------------------------------"
  echo "1. Start systemd service"
  echo "2. Stop bot"
  echo "3. Restart systemd service"
  echo "0. Back to main menu"
  echo "-------------------------------------"

  read -p "Choose an option: " choice

  case $choice in
    1) setup_systemd ;;
    2) stop_bot ;;
    3) restart_service ;;
    0) return ;;
    *) echo "Invalid option"; sleep 2; service_management_menu ;;
  esac
}

function menu() {
  clear
  echo "Automatic installer for kuma-monitoring-reporter"
  echo "-------------------------------------------"
  echo "1. Install project"
  echo "2. Configure config.json file"
  echo "3. Update project"
  echo "4. Service management"
  echo "5. Test Telegram configuration"
  echo "6. Backup logs"
  echo "7. Show project status"
  echo "8. Check dependencies"
  echo "9. Completely remove project"
  echo "0. Exit"
  echo "-------------------------------------"

  read -p "Choose an option: " choice

  case $choice in
    1) install_project ;;
    2) edit_config ;;
    3) update_project ;;
    4) service_management_menu ;;
    5) test_telegram ;;
    6) backup_logs ;;
    7) show_status ;;
    8) check_dependencies ;;
    9) uninstall_project ;;
    0) echo "Bye!"; exit 0 ;;
    *) echo "Invalid option"; sleep 2; menu ;;
  esac
}

menu