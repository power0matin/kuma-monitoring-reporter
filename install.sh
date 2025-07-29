#!/bin/bash

REPO_URL="https://github.com/power0matin/kuma-monitoring-reporter.git"
INSTALL_DIR="$HOME/kuma-monitoring-reporter"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

# Pre-checks
command -v git >/dev/null 2>&1 || { echo "❌ Git is not installed. Please install Git."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python3 is not installed."; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo "❌ pip3 is not installed."; exit 1; }

function install_project() {
  echo "📥 Installing kuma-monitoring-reporter project ..."

  if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️ Directory already exists: $INSTALL_DIR"
  else
    git clone "$REPO_URL" "$INSTALL_DIR" || {
      echo "❌ Failed to clone repository."; exit 1;
    }
  fi

  cd "$INSTALL_DIR" || exit
  echo "📦 Creating virtual environment..."
  python3 -m venv venv
  source venv/bin/activate
  echo "📦 Installing dependencies..."
  python3 -m pip install -r requirements.txt
  deactivate

  echo "✅ Installation completed successfully."
  echo "➕ First run: source $INSTALL_DIR/venv/bin/activate; python3 report.py"
}

function edit_config() {
  echo "⚙️ config.json file configuration"

  mkdir -p "$(dirname "$CONFIG_FILE")"

  read -p "🌐 Kuma Metrics URL (e.g. http://localhost:3001/metrics): " kuma_url
  read -p "🤖 Telegram bot token: " telegram_bot_token
  read -p "💬 Telegram chat ID (e.g. 123456789): " telegram_chat_id
  read -p "🔑 API token for Kuma: " auth_token
  read -p "🟢 Good threshold (ms): " good
  read -p "🟡 Warning threshold (ms): " warning
  read -p "🔴 Critical threshold (ms): " critical

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
  }
}
EOF

  echo "✅ Configuration saved successfully: $CONFIG_FILE"
}

function uninstall_project() {
  echo "⚠️ This will delete the entire project!"
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
  echo "3️⃣ Completely remove project"
  echo "0️⃣ Exit"
  echo "-------------------------------------"

  read -p "Choose an option: " choice

  case $choice in
    1) install_project ;;
    2) edit_config ;;
    3) uninstall_project ;;
    0) echo "👋 Bye!"; exit 0 ;;
    *) echo "❌ Invalid option"; sleep 2; menu ;;
  esac
}

menu