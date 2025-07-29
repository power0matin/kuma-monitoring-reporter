#!/bin/bash

REPO_URL="https://github.com/power0matin/kuma-monitoring-reporter.git"
INSTALL_DIR="$HOME/kuma-monitoring-reporter"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# چک کردن پیش‌نیازها
command -v git >/dev/null 2>&1 || { echo "❌ Git is not installed. Please install Git."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python3 is not installed."; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "❌ pip3 is not installed."; exit 1; }

function install_project() {
  echo "📥 Installing kuma-monitoring-reporter project ..."

  # چک کردن وجود دایرکتوری
  if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Directory already exists: $INSTALL_DIR"
    echo "Please use 'Update project' (option 3) or remove the directory first."
    return 1
  fi

  # اطمینان از وجود دایرکتوری والد
  mkdir -p "$(dirname "$INSTALL_DIR")" || { echo "❌ Failed to create parent directory."; exit 1; }

  # کلون کردن مخزن
  echo "📡 Cloning repository from $REPO_URL..."
  git clone "$REPO_URL" "$INSTALL_DIR" || {
    echo "❌ Failed to clone repository. Check network or repository URL."
    exit 1
  }

  cd "$INSTALL_DIR" || { echo "❌ Failed to change directory to $INSTALL_DIR"; exit 1; }
  echo "📦 Creating virtual environment..."
  python3 -m venv venv || { echo "❌ Failed to create virtual environment."; exit 1; }
  source venv/bin/activate
  echo "📦 Installing dependencies..."
  pip install -r requirements.txt || { echo "❌ Failed to install dependencies."; deactivate; exit 1; }
  deactivate

  echo "✅ Installation completed successfully."
  echo "➕ First run: source $INSTALL_DIR/venv/bin/activate; python3 report.py"
}

function update_project() {
  echo "🔄 Updating kuma-monitoring-reporter project ..."

  if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ Project directory does not exist: $INSTALL_DIR"
    echo "Please install the project first using option 1."
    exit 1
  fi

  cd "$INSTALL_DIR" || { echo "❌ Failed to change directory to $INSTALL_DIR"; exit 1; }
  echo "📥 Pulling latest changes from repository..."
  git pull origin main || {
    echo "❌ Failed to update repository. Check network or repository status."
    exit 1
  }

  echo "📦 Updating dependencies..."
  source venv/bin/activate
  pip install -r requirements.txt || { echo "❌ Failed to install dependencies."; deactivate; exit 1; }
  deactivate

  echo "✅ Project updated successfully."
  echo "➕ Run the project: source $INSTALL_DIR/venv/bin/activate; python3 report.py"
}

function edit_config() {
  echo "⚙️ Configuring config.json file..."

  mkdir -p "$(dirname "$CONFIG_FILE")" || { echo "❌ Failed to create config directory."; exit 1; }

  read -p "🌐 Kuma Metrics URL (e.g. http://localhost:3001/metrics): " kuma_url
  read -p "🤖 Telegram bot token: " telegram_bot_token
  read -p "💬 Telegram chat ID (e.g. 123456789): " telegram_chat_id
  read -p "🔑 API token for Kuma (leave empty if not needed): " auth_token
  read -p "🟢 Good threshold (ms, e.g. 200): " good
  read -p "🟡 Warning threshold (ms, e.g. 500): " warning
  read -p "🔴 Critical threshold (ms, e.g. 1000): " critical
  read -p "⏰ Report interval (minutes, e.g. 1 for every minute): " report_interval

  # اعتبارسنجی report_interval
  if ! [[ "$report_interval" =~ ^[0-9]+$ ]] || [ "$report_interval" -lt 1 ]; then
    echo "❌ Report interval must be a positive integer."
    exit 1
  }

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
  "report_interval": $report_interval
}
EOF

  echo "✅ Configuration saved successfully: $CONFIG_FILE"
}

function uninstall_project() {
  echo "⚠️ This will delete the entire project including config.json!"
  read -p "Are you sure? (y/n): " confirm
  if [[ "$confirm" == "y" ]]; then
    rm -rf "$INSTALL_DIR"
    echo "🗑️ Project deleted."
  else
    echo "❌ Operation canceled."
  fi
}

function menu() {
  clear
  echo "📡 Automatic installer for kuma-monitoring-reporter"
  echo "-------------------------------------------"
  echo "1️⃣ Install project"
  echo "2️⃣ Configure config.json file"
  echo "3️⃣ Update project"
  echo "4️⃣ Completely remove project"
  echo "0️⃣ Exit"
  echo "-------------------------------------"

  read -p "Choose an option: " choice

  case $choice in
    1) install_project ;;
    2) edit_config ;;
    3) update_project ;;
    4) uninstall_project ;;
    0) echo "👋 Bye!"; exit 0 ;;
    *) echo "❌ Invalid option"; sleep 2; menu ;;
  esac
}

menu