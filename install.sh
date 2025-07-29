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

# 🌐 Function to check GitHub connectivity
check_github_connectivity() {
    echo -e "${CYAN}🌐 Checking connectivity to GitHub...${NC}" | tee -a "$LOG_FILE"
    if ! ping -c 1 github.com >/dev/null 2>&1; then
        echo -e "${RED}❌ Cannot connect to GitHub. Check your network connection.${NC}" | tee -a "$LOG_FILE"
        read -p "Press Enter to continue..."
        return 1
    fi
    return 0
}

# 📁 Function to setup directories and log files
setup_dirs() {
    mkdir -p "$PROJECT_DIR/logs" "$PROJECT_DIR/config" "$PROJECT_DIR/core" "$PROJECT_DIR/notifier"
    touch "$PROJECT_DIR/logs/install.log" "$PROJECT_DIR/logs/error.log"
}

# 📦 Function to install system dependencies
install_system_deps() {
    setup_dirs
    echo -e "${YELLOW}📦 Installing system dependencies...${NC}" | tee -a "$LOG_FILE"
    sudo apt-get update >> "$LOG_FILE" 2>&1
    sudo apt-get install -y git python3 python3-pip python3-venv jq >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to install dependencies. Check $LOG_FILE for details.${NC}" | tee -a "$LOG_FILE"
        read -p "Press Enter to continue..."
        return 1
    }
    echo -e "${GREEN}🎉 System dependencies installed!${NC}" | tee -a "$LOG_FILE"
    return 0
}

# 🚀 Function to install project
install_project() {
    setup_dirs
    echo -e "${YELLOW}🚀 Installing kuma-monitoring-reporter...${NC}" | tee -a "$LOG_FILE"
    
    # Check GitHub connectivity
    check_github_connectivity || return 1
    
    # Remove existing directory if it's not a valid git repo
    if [ -d "$PROJECT_DIR" ] && [ ! -d "$PROJECT_DIR/.git" ]; then
        echo -e "${YELLOW}🗑 Removing invalid project directory...${NC}" | tee -a "$LOG_FILE"
        rm -rf "$PROJECT_DIR"
    fi
    
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${CYAN}📥 Cloning repository...${NC}" | tee -a "$LOG_FILE"
        git clone "$REPO_URL" "$PROJECT_DIR" >> "$LOG_FILE" 2>&1 || {
            echo -e "${RED}❌ Failed to clone repository. Check $LOG_FILE for details.${NC}" | tee -a "$LOG_FILE"
            read -p "Press Enter to continue..."
            return 1
        }
    fi
    
    cd "$PROJECT_DIR" || {
        echo -e "${RED}❌ Failed to access project directory${NC}" | tee -a "$LOG_FILE"
        read -p "Press Enter to continue..."
        return 1
    }
    
    # Check if report.py exists
    if [ ! -f "$PROJECT_DIR/report.py" ]; then
        echo -e "${RED}❌ report.py not found after cloning. Repository may be incomplete or incorrect.${NC}" | tee -a "$LOG_FILE"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${CYAN}🛠 Creating virtual environment...${NC}" | tee -a "$LOG_FILE"
    python3 -m venv venv
    source venv/bin/activate
    echo -e "${CYAN}📦 Installing Python dependencies...${NC}" | tee -a "$LOG_FILE"
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    # Create requirements.txt if it doesn't exist
    if [ ! -f requirements.txt ]; then
        echo -e "${CYAN}📝 Creating requirements.txt...${NC}" | tee -a "$LOG_FILE"
        cat > requirements.txt <<EOF
requests
schedule
EOF
    fi
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to install Python dependencies. Check $LOG_FILE for details.${NC}" | tee -a "$LOG_FILE"
        read -p "Press Enter to continue..."
        return 1
    }
    echo -e "${GREEN}🎉 Project installed successfully!${NC}" | tee -a "$LOG_FILE"
    echo -e "Run it with: ${CYAN}source $VENV_DIR/bin/activate; python3 report.py${NC}" | tee -a "$LOG_FILE"
    read -p "Press Enter to continue..."
    return 0
}

# ⚙️ Function to configure config.json
configure_json() {
    setup_dirs
    echo -e "${YELLOW}⚙️ Configuring config.json...${NC}" | tee -a "$LOG_FILE"
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
    echo -e "${GREEN}🎉 Config file created at $CONFIG_FILE${NC}" | tee -a "$LOG_FILE"
    read -p "Press Enter to continue..."
}

# 🔄 Function to update project
update_project() {
    setup_dirs
    clear
    echo -e "${YELLOW}🔄 Updating kuma-monitoring-reporter...${NC}" | tee -a "$LOG_FILE"

    check_github_connectivity || return 1

    if [ ! -d "$PROJECT_DIR/.git" ]; then
        echo -e "${RED}❌ Project directory is not a valid git repository${NC}" | tee -a "$LOG_FILE"
        echo -e "${CYAN}📥 Attempting to re-clone repository...${NC}" | tee -a "$LOG_FILE"
        rm -rf "$PROJECT_DIR"
        git clone "$REPO_URL" "$PROJECT_DIR" >> "$LOG_FILE" 2>&1 || {
            echo -e "${RED}❌ Failed to clone repository. Check $LOG_FILE for details.${NC}" | tee -a "$LOG_FILE"
            return 1
        }
    fi

    cd "$PROJECT_DIR" || {
        echo -e "${RED}❌ Failed to access project directory${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    echo -e "${CYAN}📥 Pulling latest changes...${NC}" | tee -a "$LOG_FILE"
    git pull origin main >> "$LOG_FILE" 2>&1 || git pull origin master >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to pull latest changes.${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    if [ ! -f "$PROJECT_DIR/report.py" ]; then
        echo -e "${RED}❌ report.py not found after update.${NC}" | tee -a "$LOG_FILE"
        return 1
    fi

    if [ ! -f "$VENV_DIR/bin/activate" ]; then
        echo -e "${CYAN}📦 Creating virtual environment...${NC}" | tee -a "$LOG_FILE"
        python3 -m venv "$VENV_DIR" || {
            echo -e "${RED}❌ Failed to create virtual environment${NC}" | tee -a "$LOG_FILE"
            return 1
        }
    fi

    source "$VENV_DIR/bin/activate" || {
        echo -e "${RED}❌ Failed to activate virtual environment${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    echo -e "${CYAN}📦 Updating Python dependencies...${NC}" | tee -a "$LOG_FILE"
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    if [ ! -f requirements.txt ]; then
        echo -e "${CYAN}📝 Creating requirements.txt...${NC}" | tee -a "$LOG_FILE"
        cat > requirements.txt <<EOF
requests
schedule
EOF
    fi
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to update Python dependencies${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    VERSION=$(git describe --tags 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}🎉 Project updated to version: $VERSION${NC}" | tee -a "$LOG_FILE"
    echo -e "Run it with: ${CYAN}source $VENV_DIR/bin/activate; python3 report.py${NC}" | tee -a "$LOG_FILE"
}

# 🛠 Function to setup systemd service
setup_service() {
    setup_dirs
    clear
    echo -e "${YELLOW}🛠 Setting up systemd service...${NC}" | tee -a "$LOG_FILE"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}" | tee -a "$LOG_FILE"
        return 1
    fi

    if [ ! -f "$PROJECT_DIR/report.py" ]; then
        echo -e "${RED}❌ report.py not found in $PROJECT_DIR${NC}" | tee -a "$LOG_FILE"
        return 1
    fi

    echo -e "${CYAN}⚙️ Creating systemd service file...${NC}" | tee -a "$LOG_FILE"
    sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Kuma Monitoring Reporter Service
After=network.target

[Service]
ExecStart=$VENV_DIR/bin/python3 $PROJECT_DIR/report.py
WorkingDirectory=$PROJECT_DIR
Restart=always
User=$USER
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to reload systemd daemon${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    sudo systemctl enable "$SERVICE_NAME" >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to enable $SERVICE_NAME${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    sudo systemctl start "$SERVICE_NAME" >> "$LOG_FILE" 2>&1 || {
        echo -e "${RED}❌ Failed to start $SERVICE_NAME${NC}" | tee -a "$LOG_FILE"
        return 1
    }

    echo -e "${GREEN}🎉 Service $SERVICE_NAME started successfully${NC}" | tee -a "$LOG_FILE"
    sudo systemctl status "$SERVICE_NAME" --no-pager
}


# 💾 Function to backup logs
backup_logs() {
    setup_dirs
    echo -e "${YELLOW}💾 Backing up logs...${NC}" | tee -a "$LOG_FILE"
    backup_dir="$PROJECT_DIR/logs/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r "$PROJECT_DIR/logs/"*.log "$backup_dir" 2>/dev/null || {
        echo -e "${RED}❌ No logs found to backup${NC}" | tee -a "$LOG_FILE"
    }
    echo -e "${GREEN}✅ Logs backed up to $backup_dir${NC}" | tee -a "$LOG_FILE"
    read -p "Press Enter to continue..."
}

# 📊 Function to show project status
show_status() {
    setup_dirs
    echo -e "${YELLOW}📊 Checking project status...${NC}" | tee -a "$LOG_FILE"
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${GREEN}✅ Project directory: $PROJECT_DIR${NC}" | tee -a "$LOG_FILE"
        if [ -f "$CONFIG_FILE" ]; then
            echo -e "${GREEN}✅ Config file exists: $CONFIG_FILE${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${RED}❌ Config file missing: $CONFIG_FILE${NC}" | tee -a "$LOG_FILE"
        fi
        if [ -f "$PROJECT_DIR/report.py" ]; then
            echo -e "${GREEN}✅ report.py exists: $PROJECT_DIR/report.py${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${RED}❌ report.py missing: $PROJECT_DIR/report.py${NC}" | tee -a "$LOG_FILE"
        fi
        if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ Service $SERVICE_NAME is running${NC}" | tee -a "$LOG_FILE"
            sudo systemctl status "$SERVICE_NAME" --no-pager
        else
            echo -e "${RED}❌ Service $SERVICE_NAME is not running${NC}" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}" | tee -a "$LOG_FILE"
    fi
    read -p "Press Enter to continue..."
}

# 🔍 Function to check dependencies
check_deps() {
    setup_dirs
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}" | tee -a "$LOG_FILE"
    for cmd in git python3 pip jq; do
        if command_exists "$cmd"; then
            echo -e "${GREEN}✅ $cmd is installed${NC}" | tee -a "$LOG_FILE"
        else
            echo -e "${RED}❌ $cmd is not installed${NC}" | tee -a "$LOG_FILE"
        fi
    done
    if [ -d "$VENV_DIR" ]; then
        source "$VENV_DIR/bin/activate"
        pip list
    else
        echo -e "${RED}❌ Virtual environment not found: $VENV_DIR${NC}" | tee -a "$LOG_FILE"
    fi
    read -p "Press Enter to continue..."
}

# 🗑️ Function to remove project
remove_project() {
    setup_dirs
    echo -e "${YELLOW}🗑️ Removing kuma-monitoring-reporter...${NC}" | tee -a "$LOG_FILE"
    if [ -d "$PROJECT_DIR" ]; then
        stop_bot
        sudo rm -f "$SERVICE_FILE"
        sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}✅ Project removed successfully${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}" | tee -a "$LOG_FILE"
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
            *) echo -e "${RED}❌ Invalid option${NC}" | tee -a "$LOG_FILE"; read -p "Press Enter to continue..." ;;
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
        0) clear; echo -e "${YELLOW}⬅️ Thanks for using kuma-monitoring-reporter! Exiting...${NC}" | tee -a "$LOG_FILE"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option${NC}" | tee -a "$LOG_FILE"; read -p "Press Enter to continue..." ;;
    esac
done