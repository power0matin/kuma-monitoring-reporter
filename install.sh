#!/bin/bash

# 🌟 Automatic installer for kuma-monitoring-reporter 🌟

REPO_URL="https://github.com/power0matin/kuma-monitoring-reporter.git"
PROJECT_DIR="$HOME/kuma-monitoring-reporter"
VENV_DIR="$PROJECT_DIR/venv"
CONFIG_FILE="$PROJECT_DIR/config/config.json"
SERVICE_NAME="kuma-reporter"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# 🎨 Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 🛠️ Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 📦 Function to install system dependencies
install_system_deps() {
    echo -e "${YELLOW}📦 Installing system dependencies...${NC}"
    sudo apt-get update
    sudo apt-get install -y git python3 python3-pip python3-venv jq || {
        echo -e "${RED}❌ Failed to install system dependencies${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ System dependencies installed${NC}"
}

# 🚀 Function to install project
install_project() {
    echo -e "${YELLOW}🚀 Installing kuma-monitoring-reporter...${NC}"
    if [ ! -d "$PROJECT_DIR" ]; then
        git clone "$REPO_URL" "$PROJECT_DIR" || {
            echo -e "${RED}❌ Failed to clone repository${NC}"
            exit 1
        }
    fi
    cd "$PROJECT_DIR" || exit 1
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt || {
        echo -e "${RED}❌ Failed to install Python dependencies${NC}"
        exit 1
    }
    mkdir -p config logs
    touch logs/error.log
    echo -e "${GREEN}✅ Project installed successfully${NC}"
    echo -e "Run the project: source $VENV_DIR/bin/activate; python3 report.py"
}

# ⚙️ Function to configure config.json
configure_json() {
    echo -e "${YELLOW}⚙️ Configuring config.json...${NC}"
    mkdir -p "$PROJECT_DIR/config"
    read -p "🌐 Enter Uptime Kuma metrics URL (e.g., http://your-server:3001/metrics): " kuma_url
    read -p "🤖 Enter Telegram bot token: " telegram_bot_token
    read -p "💬 Enter Telegram chat ID: " telegram_chat_id
    read -p "🔑 Enter Uptime Kuma API key or password (leave empty if not required): " auth_token
    read -p "✅ Enter good threshold (ms): " good
    read -p "⚠️ Enter warning threshold (ms): " warning
    read -p "🚨 Enter critical threshold (ms): " critical
    read -p "⏰ Enter report interval (minutes): " report_interval

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
    echo -e "${GREEN}✅ Config file created at $CONFIG_FILE${NC}"
}

# 🔄 Function to update project
update_project() {
    echo -e "${YELLOW}🔄 Updating kuma-monitoring-reporter...${NC}"
    cd "$PROJECT_DIR" || {
        echo -e "${RED}❌ Project directory not found${NC}"
        exit 1
    }
    git pull origin main || {
        echo -e "${RED}❌ Failed to pull latest changes${NC}"
        exit 1
    }
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt || {
        echo -e "${RED}❌ Failed to update Python dependencies${NC}"
        exit 1
    }
    echo -e "${GREEN}✅ Project updated successfully${NC}"
    echo -e "Run the project: source $VENV_DIR/bin/activate; python3 report.py"
}

# 🛠️ Function to setup systemd service
setup_service() {
    echo -e "${YELLOW}🛠️ Setting up systemd service...${NC}"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Config file not found. Please configure it first.${NC}"
        exit 1
    fi
    sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Kuma Monitoring Reporter Service
After=network.target

[Service]
ExecStart=$VENV_DIR/bin/python3 $PROJECT_DIR/report.py
WorkingDirectory=$PROJECT_DIR
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl start "$SERVICE_NAME"
    echo -e "${GREEN}✅ Systemd service setup and started${NC}"
    sudo systemctl status "$SERVICE_NAME" --no-pager
}

# 🛑 Function to stop bot
stop_bot() {
    echo -e "${YELLOW}🛑 Stopping bot...${NC}"
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl stop "$SERVICE_NAME"
        echo -e "${GREEN}✅ Bot stopped${NC}"
    else
        echo -e "${RED}❌ Bot is not running${NC}"
    fi
}

# 🔄 Function to restart bot
restart_bot() {
    echo -e "${YELLOW}🔄 Restarting bot...${NC}"
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl restart "$SERVICE_NAME"
        echo -e "${GREEN}✅ Bot restarted${NC}"
        sudo systemctl status "$SERVICE_NAME" --no-pager
    else
        echo -e "${RED}❌ Bot is not running${NC}"
    fi
}

# 📬 Function to test Telegram configuration
test_telegram() {
    echo -e "${YELLOW}📬 Testing Telegram configuration...${NC}"
    source "$VENV_DIR/bin/activate"
    python3 -c "
import json
import requests
with open('$CONFIG_FILE') as f:
    config = json.load(f)
url = f'https://api.telegram.org/bot{config[\"telegram_bot_token\"]}/sendMessage'
data = {'chat_id': config['telegram_chat_id'], 'text': 'Test message from kuma-monitoring-reporter'}
response = requests.post(url, data=data)
if response.status_code == 200:
    print('\033[0;32m✅ Test message sent successfully.\033[0m')
else:
    print(f'\033[0;31m❌ Failed to send test message: {response.text}\033[0m')
"
}

# 💾 Function to backup logs
backup_logs() {
    echo -e "${YELLOW}💾 Backing up logs...${NC}"
    backup_dir="$PROJECT_DIR/logs/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r "$PROJECT_DIR/logs/"*.log "$backup_dir" 2>/dev/null || {
        echo -e "${RED}❌ No logs found to backup${NC}"
    }
    echo -e "${GREEN}✅ Logs backed up to $backup_dir${NC}"
}

# 📊 Function to show project status
show_status() {
    echo -e "${YELLOW}📊 Checking project status...${NC}"
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${GREEN}✅ Project directory: $PROJECT_DIR${NC}"
        if [ -f "$CONFIG_FILE" ]; then
            echo -e "${GREEN}✅ Config file exists: $CONFIG_FILE${NC}"
        else
            echo -e "${RED}❌ Config file missing: $CONFIG_FILE${NC}"
        fi
        if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ Service $SERVICE_NAME is running${NC}"
            sudo systemctl status "$SERVICE_NAME" --no-pager
        else
            echo -e "${RED}❌ Service $SERVICE_NAME is not running${NC}"
        fi
    else
        echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"
    fi
}

# 🔍 Function to check dependencies
check_deps() {
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
    for cmd in git python3 pip jq; do
        if command_exists "$cmd"; then
            echo -e "${GREEN}✅ $cmd is installed${NC}"
        else
            echo -e "${RED}❌ $cmd is not installed${NC}"
        fi
    done
    if [ -d "$VENV_DIR" ]; then
        source "$VENV_DIR/bin/activate"
        pip list
    else
        echo -e "${RED}❌ Virtual environment not found: $VENV_DIR${NC}"
    fi
}

# 🗑️ Function to remove project
remove_project() {
    echo -e "${YELLOW}🗑️ Removing kuma-monitoring-reporter...${NC}"
    if [ -d "$PROJECT_DIR" ]; then
        stop_bot
        sudo rm -f "$SERVICE_FILE"
        sudo systemctl daemon-reload
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}✅ Project removed successfully${NC}"
    else
        echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"
    fi
}

# 🚀 Service Management Submenu
service_management() {
    while true; do
        echo -e "\n🌟 Service Management Menu"
        echo "-------------------------------------"
        echo "1. Stop bot 🛑"
        echo "2. Restart bot 🔄"
        echo "3. Show service status 📊"
        echo "4. Setup systemd service 🛠️"
        echo "0. Back to main menu ⬅️"
        echo "-------------------------------------"
        read -p "Choose an option: " sub_choice
        case $sub_choice in
            1) stop_bot ;;
            2) restart_bot ;;
            3) show_status ;;
            4) setup_service ;;
            0) break ;;
            *) echo -e "${RED}❌ Invalid option${NC}" ;;
        esac
    done
}

# 📋 Main Menu
while true; do
    echo -e "\n🌟 kuma-monitoring-reporter Installer V1"
    echo "-------------------------------------"
    echo "1. Install project 🚀"
    echo "2. Configure config.json ⚙️"
    echo "3. Update project 🔄"
    echo "4. Service management 🛠️"
    echo "5. Test Telegram configuration 📬"
    echo "6. Backup logs 💾"
    echo "7. Check dependencies 🔍"
    echo "8. Completely remove project 🗑️"
    echo "0. Exit ⬅️"
    echo "-------------------------------------"
    read -p "Choose an option: " choice

    case $choice in
        1) install_system_deps; install_project ;;
        2) configure_json ;;
        3) update_project ;;
        4) service_management ;;
        5) test_telegram ;;
        6) backup_logs ;;
        7) check_deps ;;
        8) remove_project ;;
        0) echo -e "${YELLOW}⬅️ Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option${NC}" ;;
    esac
done