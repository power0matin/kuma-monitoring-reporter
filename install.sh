#!/bin/bash

# 🌟 kuma-monitoring-reporter Installer 🚀

REPO_URL="https://github.com/power0matin/kuma-monitoring-reporter.git"
PROJECT_DIR="$HOME/kuma-monitoring-reporter"
VENV_DIR="$PROJECT_DIR/venv"
CONFIG_FILE="$PROJECT_DIR/config/config.json"
SERVICE_NAME="kuma-reporter"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
LOG_FILE="$PROJECT_DIR/logs/install.log"

# 🎨 Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 🛠️ Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 📁 Function to setup directories and log files
setup_dirs() {
    mkdir -p "$PROJECT_DIR/logs" "$PROJECT_DIR/config"
    touch "$PROJECT_DIR/logs/install.log" "$PROJECT_DIR/logs/error.log"
}

# 📈 Simple progress bar (always completes to 100%)
progress_bar() {
    local duration=$1
    local width=30
    for ((i=0; i<=100; i+=5)); do
        local done=$((i * width / 100))
        local undone=$((width - done))
        local done_bar=$(printf "%${done}s" | tr ' ' '█')
        local undone_bar=$(printf "%${undone}s" | tr ' ' ' ')
        printf "\r${YELLOW}Processing... [${done_bar}${undone_bar}] $i%%${NC}"
        sleep $(echo "$duration/20" | bc -l)
    done
    echo -e "\n"
}

# 📦 Function to install system dependencies
install_system_deps() {
    setup_dirs
    echo -e "${YELLOW}📦 Installing system dependencies...${NC}"
    progress_bar 10
    sudo apt-get update >> "$LOG_FILE" 2>&1
    sudo apt-get install -y git python3 python3-pip python3-venv jq >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to install dependencies. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    }
    echo -e "${GREEN}🎉 System dependencies installed!${NC}"
    return 0
}

# 🚀 Function to install project
install_project() {
    setup_dirs
    echo -e "${YELLOW}🚀 Installing kuma-monitoring-reporter...${NC}"
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${CYAN}📥 Cloning repository...${NC}"
        progress_bar 10
        git clone "$REPO_URL" "$PROJECT_DIR" >> "$LOG_FILE" 2>&1 || {
            echo -e "${RED}❌ Failed to clone repository. Check $LOG_FILE for details.${NC}"
            read -p "Press Enter to continue..."
            return 1
        }
    fi
    cd "$PROJECT_DIR" || {
        echo -e "${RED}❌ Failed to access project directory${NC}"
        read -p "Press Enter to continue..."
        return 1
    }
    echo -e "${CYAN}🛠 Creating virtual environment...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    echo -e "${CYAN}📦 Installing Python dependencies...${NC}"
    progress_bar 10
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    # Create requirements.txt if it doesn't exist
    if [ ! -f requirements.txt ]; then
        echo -e "${CYAN}📝 Creating requirements.txt...${NC}"
        cat > requirements.txt <<EOF
requests
schedule
EOF
    fi
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to install Python dependencies. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    }
    echo -e "${GREEN}🎉 Project installed successfully!${NC}"
    echo -e "Run it with: ${CYAN}source $VENV_DIR/bin/activate; python3 report.py${NC}"
    read -p "Press Enter to continue..."
    return 0
}

# ⚙️ Function to configure config.json
configure_json() {
    setup_dirs
    echo -e "${YELLOW}⚙️ Configuring config.json...${NC}"
    echo -e "${CYAN}📝 Let's set up your configuration:${NC}"
    read -p "🌐 Uptime Kuma metrics URL (e.g., http://localhost:3001/metrics): " kuma_url
    read -p "🤖 Telegram bot token: " telegram_bot_token
    read -p "💬 Telegram chat ID: " telegram_chat_id
    read -p "🔑 Uptime Kuma API key or password (press Enter if not needed): " auth_token
    read -p "✅ Good threshold (ms, e.g., 100): " good
    read -p "⚠️ Warning threshold (ms, e.g., 250): " warning
    read -p "🚨 Critical threshold (ms, e.g., 500): " critical
    read -p "⏰ Report interval (minutes, e.g., 1): " report_interval

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
    echo -e "${GREEN}🎉 Config file created at $CONFIG_FILE${NC}"
    read -p "Press Enter to continue..."
}

# 🔄 Function to update project
update_project() {
    setup_dirs
    echo -e "${YELLOW}🔄 Updating kuma-monitoring-reporter...${NC}"
    cd "$PROJECT_DIR" || {
        echo -e "${RED}❌ Project directory not found${NC}"
        read -p "Press Enter to continue..."
        return 1
    }
    echo -e "${CYAN}📥 Pulling latest changes...${NC}"
    progress_bar 8
    git pull origin main >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to pull latest changes. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    }
    source venv/bin/activate
    echo -e "${CYAN}📦 Updating Python dependencies...${NC}"
    progress_bar 8
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    # Ensure requirements.txt exists
    if [ ! -f requirements.txt ]; then
        echo -e "${CYAN}📝 Creating requirements.txt...${NC}"
        cat > requirements.txt <<EOF
requests
schedule
EOF
    fi
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to update Python dependencies. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    }
    # Show project version if available
    VERSION=$(git describe --tags 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}🎉 Project updated to version: $VERSION${NC}"
    echo -e "Run it with: ${CYAN}source $VENV_DIR/bin/activate; python3 report.py${NC}"
    read -p "Press Enter to continue..."
}

setup_service() {
    setup_dirs
    echo -e "${YELLOW}🛠 Setting up systemd service...${NC}"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Config file not found. Please configure it first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    echo -e "${CYAN}⚙️ Creating service file...${NC}"
    progress_bar 5
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
    sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
    sudo systemctl enable "$SERVICE_NAME" >> "$LOG_FILE" 2>&1
    sudo systemctl start "$SERVICE_NAME" >> "$LOG_FILE" 2>&1
    echo -e "${GREEN}🎉 Systemd service setup and started${NC}"
    sudo systemctl status "$SERVICE_NAME" --no-pager
    read -p "Press Enter to continue..."
}

# 🛑 Function to stop bot
stop_bot() {
    setup_dirs
    echo -e "${YELLOW}🛑 Stopping bot...${NC}"
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl stop "$SERVICE_NAME" >> "$LOG_FILE" 2>&1
        echo -e "${GREEN}✅ Bot stopped${NC}"
    else
        echo -e "${RED}❌ Bot is not running${NC}"
    fi
    read -p "Press Enter to continue..."
}

# 🔄 Function to restart bot
restart_bot() {
    setup_dirs
    echo -e "${YELLOW}🔄 Restarting bot...${NC}"
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        sudo systemctl restart "$SERVICE_NAME" >> "$LOG_FILE" 2>&1
        echo -e "${GREEN}✅ Bot restarted${NC}"
        sudo systemctl status "$SERVICE_NAME" --no-pager
    else
        echo -e "${RED}❌ Bot is not running${NC}"
    fi
    read -p "Press Enter to continue..."
}

# 📬 Function to test Telegram configuration
test_telegram() {
    setup_dirs
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
    read -p "Press Enter to continue..."
}

# 💾 Function to backup logs
backup_logs() {
    setup_dirs
    echo -e "${YELLOW}💾 Backing up logs...${NC}"
    backup_dir="$PROJECT_DIR/logs/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r "$PROJECT_DIR/logs/"*.log "$backup_dir" 2>/dev/null || {
        echo -e "${RED}❌ No logs found to backup${NC}"
    }
    echo -e "${GREEN}✅ Logs backed up to $backup_dir${NC}"
    read -p "Press Enter to continue..."
}

# 📊 Function to show project status
show_status() {
    setup_dirs
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
    read -p "Press Enter to continue..."
}

# 🔍 Function to check dependencies
check_deps() {
    setup_dirs
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
    read -p "Press Enter to continue..."
}

# 🗑️ Function to remove project
remove_project() {
    setup_dirs
    echo -e "${YELLOW}🗑️ Removing kuma-monitoring-reporter...${NC}"
    if [ -d "$PROJECT_DIR" ]; then
        stop_bot
        sudo rm -f "$SERVICE_FILE"
        sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}✅ Project removed successfully${NC}"
    else
        echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"
    fi
    read -p "Press Enter to continue..."
}

# 🚀 Service Management Submenu
service_management() {
    while true; do
        clear
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
            *) echo -e "${RED}❌ Invalid option${NC}"; read -p "Press Enter to continue..." ;;
        esac
    done
}

# 📋 Main Menu
while true; do
    clear
    echo -e "\n🌟 kuma-monitoring-reporter Installer"
    echo "-------------------------------------"
    echo -e "${CYAN}Welcome to the installer! Choose an action:${NC}"
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
        1) install_system_deps && install_project ;;
        2) configure_json ;;
        3) update_project ;;
        4) service_management ;;
        5) test_telegram ;;
        6) backup_logs ;;
        7) check_deps ;;
        8) remove_project ;;
        0) clear; echo -e "${YELLOW}⬅️ Thanks for using kuma-monitoring-reporter! Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option${NC}"; read -p "Press Enter to continue..." ;;
    esac
done