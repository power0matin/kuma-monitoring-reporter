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

# ✅ Function to check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}🔐 This operation requires sudo privileges. Please enter your password:${NC}"
        if ! sudo true; then
            echo -e "${RED}❌ Sudo privileges required. Exiting.${NC}"
            return 1
        fi
    fi
    return 0
}

# 🛡️ Function to validate URL format
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo -e "${RED}❌ Invalid URL format. Please use http:// or https://${NC}"
        return 1
    fi
    return 0
}

# 🔢 Function to validate numeric input
validate_number() {
    local num="$1"
    local field="$2"
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ Invalid $field. Please enter a positive integer.${NC}"
        return 1
    fi
    return 0
}

# 🔑 Function to validate telegram bot token format
validate_telegram_token() {
    local token="$1"
    if [[ ! "$token" =~ ^[0-9]+:[A-Za-z0-9_-]+$ ]]; then
        echo -e "${YELLOW}⚠️ Warning: Telegram bot token format looks invalid. Expected format: 123456789:ABCDEF...${NC}"
        read -p "Continue anyway? (y/n): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]]
    fi
    return 0
}

# 📦 Function to install system dependencies
install_system_deps() {
    setup_dirs
    echo -e "${YELLOW}📦 Installing system dependencies...${NC}"
    
    # Check if we have sudo access
    if ! check_sudo; then
        return 1
    fi
    
    # Update package list
    echo -e "${CYAN}🔄 Updating package list...${NC}"
    if ! sudo apt-get update >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to update package list. Check $LOG_FILE for details.${NC}"
        echo -e "${CYAN}💡 You may need to run: sudo apt-get update manually${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Install dependencies
    echo -e "${CYAN}📦 Installing git, python3, python3-pip, python3-venv, jq...${NC}"
    if ! sudo apt-get install -y git python3 python3-pip python3-venv jq >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to install dependencies. Check $LOG_FILE for details.${NC}"
        echo -e "${CYAN}💡 Try running manually: sudo apt-get install -y git python3 python3-pip python3-venv jq${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}🎉 System dependencies installed!${NC}"
    return 0
}

# 🚀 Function to install project
install_project() {
    setup_dirs
    echo -e "${YELLOW}🚀 Installing kuma-monitoring-reporter...${NC}"
    
    # Remove existing directory if it exists and is not empty
    if [ -d "$PROJECT_DIR" ] && [ "$(ls -A "$PROJECT_DIR" 2>/dev/null)" ]; then
        echo -e "${YELLOW}⚠️ Project directory already exists. Do you want to remove it and reinstall?${NC}"
        read -p "Remove existing installation? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR"
        else
            echo -e "${CYAN}💡 Skipping installation. Use update option instead.${NC}"
            read -p "Press Enter to continue..."
            return 0
        fi
    fi
    
    # Clone repository
    echo -e "${CYAN}📥 Cloning repository...${NC}"
    if ! git clone "$REPO_URL" "$PROJECT_DIR" >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to clone repository. Check $LOG_FILE for details.${NC}"
        echo -e "${CYAN}💡 Check your internet connection and repository URL${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Change to project directory
    if ! cd "$PROJECT_DIR"; then
        echo -e "${RED}❌ Failed to access project directory${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Create virtual environment
    echo -e "${CYAN}🛠 Creating virtual environment...${NC}"
    if ! python3 -m venv venv >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to create virtual environment. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Activate virtual environment
    if ! source venv/bin/activate; then
        echo -e "${RED}❌ Failed to activate virtual environment${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Upgrade pip
    echo -e "${CYAN}⬆️ Upgrading pip...${NC}"
    if ! pip install --upgrade pip >> "$LOG_FILE" 2>&1; then
        echo -e "${YELLOW}⚠️ Failed to upgrade pip, continuing anyway...${NC}"
    fi
    
    # Create requirements.txt if it doesn't exist
    if [ ! -f requirements.txt ]; then
        echo -e "${CYAN}📝 Creating requirements.txt...${NC}"
        cat > requirements.txt <<EOF
requests>=2.25.1
schedule>=1.1.0
python-telegram-bot>=13.7
EOF
    fi
    
    # Install Python dependencies
    echo -e "${CYAN}📦 Installing Python dependencies...${NC}"
    if ! pip install -r requirements.txt >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to install Python dependencies. Check $LOG_FILE for details.${NC}"
        echo -e "${CYAN}💡 Try running manually: pip install -r requirements.txt${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}🎉 Project installed successfully!${NC}"
    echo -e "${CYAN}📍 Project location: $PROJECT_DIR${NC}"
    echo -e "${CYAN}🏃 Run it with: source $VENV_DIR/bin/activate && python3 report.py${NC}"
    read -p "Press Enter to continue..."
    return 0
}

# ⚙️ Function to configure config.json
configure_json() {
    setup_dirs
    echo -e "${YELLOW}⚙️ Configuring config.json...${NC}"
    echo -e "${CYAN}📝 Let's set up your configuration:${NC}"
    
    # Get and validate Kuma URL
    while true; do
        read -p "🌐 Uptime Kuma metrics URL (e.g., http://localhost:3001/metrics): " kuma_url
        if [ -z "$kuma_url" ]; then
            echo -e "${RED}❌ URL cannot be empty${NC}"
            continue
        fi
        if validate_url "$kuma_url"; then
            break
        fi
    done
    
    # Get and validate Telegram bot token
    while true; do
        read -p "🤖 Telegram bot token: " telegram_bot_token
        if [ -z "$telegram_bot_token" ]; then
            echo -e "${RED}❌ Bot token cannot be empty${NC}"
            continue
        fi
        if validate_telegram_token "$telegram_bot_token"; then
            break
        fi
    done
    
    # Get and validate Telegram chat ID
    while true; do
        read -p "💬 Telegram chat ID: " telegram_chat_id
        if [ -z "$telegram_chat_id" ]; then
            echo -e "${RED}❌ Chat ID cannot be empty${NC}"
            continue
        fi
        break
    done
    
    # Get optional auth token
    read -p "🔑 Uptime Kuma API key or password (press Enter if not needed): " auth_token
    
    # Get and validate thresholds
    while true; do
        read -p "✅ Good threshold (ms, e.g., 100): " good
        if validate_number "$good" "good threshold"; then
            break
        fi
    done
    
    while true; do
        read -p "⚠️ Warning threshold (ms, e.g., 250): " warning
        if validate_number "$warning" "warning threshold"; then
            if [ "$warning" -le "$good" ]; then
                echo -e "${RED}❌ Warning threshold should be greater than good threshold${NC}"
                continue
            fi
            break
        fi
    done
    
    while true; do
        read -p "🚨 Critical threshold (ms, e.g., 500): " critical
        if validate_number "$critical" "critical threshold"; then
            if [ "$critical" -le "$warning" ]; then
                echo -e "${RED}❌ Critical threshold should be greater than warning threshold${NC}"
                continue
            fi
            break
        fi
    done
    
    # Get and validate report interval
    while true; do
        read -p "⏰ Report interval (minutes, e.g., 1): " report_interval
        if validate_number "$report_interval" "report interval"; then
            if [ "$report_interval" -lt 1 ]; then
                echo -e "${RED}❌ Report interval should be at least 1 minute${NC}"
                continue
            fi
            break
        fi
    done
    
    # Create config file with proper JSON formatting
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
    
    # Validate JSON format
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${RED}❌ Invalid JSON format in config file${NC}"
        return 1
    fi
    
    echo -e "${GREEN}🎉 Config file created at $CONFIG_FILE${NC}"
    read -p "Press Enter to continue..."
    return 0
}

# 🔄 Function to update project
update_project() {
    setup_dirs
    echo -e "${YELLOW}🔄 Updating kuma-monitoring-reporter...${NC}"
    
    # Check if project directory exists
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}❌ Project directory not found. Please install the project first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Change to project directory
    if ! cd "$PROJECT_DIR"; then
        echo -e "${RED}❌ Failed to access project directory${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Check if it's a git repository
    if [ ! -d ".git" ]; then
        echo -e "${RED}❌ Not a git repository. Please reinstall the project.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Backup current config if exists
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
        echo -e "${CYAN}💾 Config backed up to ${CONFIG_FILE}.backup${NC}"
    fi
    
    # Pull latest changes
    echo -e "${CYAN}📥 Pulling latest changes...${NC}"
    if ! git pull origin main >> "$LOG_FILE" 2>&1; then
        echo -e "${CYAN}📥 Trying to pull from master branch...${NC}"
        if ! git pull origin master >> "$LOG_FILE" 2>&1; then
            echo -e "${RED}❌ Failed to pull latest changes. Check $LOG_FILE for details.${NC}"
            read -p "Press Enter to continue..."
            return 1
        fi
    fi
    
    # Activate virtual environment
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}⚠️ Virtual environment not found. Creating new one...${NC}"
        python3 -m venv venv
    fi
    
    if ! source venv/bin/activate; then
        echo -e "${RED}❌ Failed to activate virtual environment${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Upgrade pip
    echo -e "${CYAN}⬆️ Upgrading pip...${NC}"
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    
    # Ensure requirements.txt exists
    if [ ! -f requirements.txt ]; then
        echo -e "${CYAN}📝 Creating requirements.txt...${NC}"
        cat > requirements.txt <<EOF
requests>=2.25.1
schedule>=1.1.0
python-telegram-bot>=13.7
EOF
    fi
    
    # Update Python dependencies
    echo -e "${CYAN}📦 Updating Python dependencies...${NC}"
    if ! pip install --upgrade -r requirements.txt >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to update Python dependencies. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Restore config if backup exists
    if [ -f "${CONFIG_FILE}.backup" ]; then
        if [ ! -f "$CONFIG_FILE" ] || [ "$CONFIG_FILE" -ot "${CONFIG_FILE}.backup" ]; then
            cp "${CONFIG_FILE}.backup" "$CONFIG_FILE"
            echo -e "${CYAN}🔄 Config restored from backup${NC}"
        fi
    fi
    
    # Show project version if available
    VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}🎉 Project updated to version: $VERSION${NC}"
    echo -e "${CYAN}🏃 Run it with: source $VENV_DIR/bin/activate && python3 report.py${NC}"
    read -p "Press Enter to continue..."
    return 0
}

# 🛠 Function to setup systemd service
setup_service() {
    setup_dirs
    echo -e "${YELLOW}🛠 Setting up systemd service...${NC}"
    
    # Check sudo access
    if ! check_sudo; then
        return 1
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Config file not found. Please configure it first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Check if report.py exists
    if [ ! -f "$PROJECT_DIR/report.py" ]; then
        echo -e "${RED}❌ report.py not found in $PROJECT_DIR. Please ensure the project is installed correctly.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Check if virtual environment exists
    if [ ! -f "$VENV_DIR/bin/python3" ]; then
        echo -e "${RED}❌ Virtual environment not found. Please install the project first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Stop service if running
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${CYAN}🛑 Stopping existing service...${NC}"
        sudo systemctl stop "$SERVICE_NAME"
    fi
    
    # Create service file
    echo -e "${CYAN}⚙️ Creating service file...${NC}"
    sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Kuma Monitoring Reporter Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$VENV_DIR/bin/python3 $PROJECT_DIR/report.py
WorkingDirectory=$PROJECT_DIR
Restart=always
RestartSec=10
User=$USER
Group=$USER
Environment=PYTHONPATH=$PROJECT_DIR
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd daemon
    if ! sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to reload systemd daemon. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Enable service
    if ! sudo systemctl enable "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to enable $SERVICE_NAME. Check $LOG_FILE for details.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Start service
    if ! sudo systemctl start "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
        echo -e "${RED}❌ Failed to start $SERVICE_NAME. Check $LOG_FILE for details.${NC}"
        echo -e "${CYAN}💡 Check logs with: sudo journalctl -u $SERVICE_NAME -f${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}🎉 Systemd service setup and started successfully!${NC}"
    echo -e "${CYAN}📊 Service status:${NC}"
    sudo systemctl status "$SERVICE_NAME" --no-pager --lines=10
    echo -e "${CYAN}💡 Monitor logs with: sudo journalctl -u $SERVICE_NAME -f${NC}"
    read -p "Press Enter to continue..."
    return 0
}

# 🛑 Function to stop bot
stop_bot() {
    setup_dirs
    echo -e "${YELLOW}🛑 Stopping bot...${NC}"
    
    if ! check_sudo; then
        return 1
    fi
    
    if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
        if sudo systemctl stop "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}✅ Bot stopped successfully${NC}"
        else
            echo -e "${RED}❌ Failed to stop bot. Check $LOG_FILE for details.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Bot is not running${NC}"
    fi
    read -p "Press Enter to continue..."
}

# 🔄 Function to restart bot
restart_bot() {
    setup_dirs
    echo -e "${YELLOW}🔄 Restarting bot...${NC}"
    
    if ! check_sudo; then
        return 1
    fi
    
    if sudo systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        if sudo systemctl restart "$SERVICE_NAME" >> "$LOG_FILE" 2>&1; then
            echo -e "${GREEN}✅ Bot restarted successfully${NC}"
            sudo systemctl status "$SERVICE_NAME" --no-pager --lines=10
        else
            echo -e "${RED}❌ Failed to restart bot. Check $LOG_FILE for details.${NC}"
        fi
    else
        echo -e "${RED}❌ Service is not enabled. Please setup the service first.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# 📬 Function to test Telegram configuration
test_telegram() {
    setup_dirs
    echo -e "${YELLOW}📬 Testing Telegram configuration...${NC}"
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Config file not found. Please configure it first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Check if virtual environment exists
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}❌ Virtual environment not found. Please install the project first.${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Activate virtual environment and test
    source "$VENV_DIR/bin/activate"
    python3 -c "
import json
import sys
import requests

try:
    with open('$CONFIG_FILE') as f:
        config = json.load(f)
    
    bot_token = config.get('telegram_bot_token', '')
    chat_id = config.get('telegram_chat_id', '')
    
    if not bot_token or not chat_id:
        print('\033[0;31m❌ Missing bot token or chat ID in config\033[0m')
        sys.exit(1)
    
    url = f'https://api.telegram.org/bot{bot_token}/sendMessage'
    data = {
        'chat_id': chat_id, 
        'text': '🧪 Test message from kuma-monitoring-reporter installer'
    }
    
    response = requests.post(url, data=data, timeout=10)
    
    if response.status_code == 200:
        print('\033[0;32m✅ Test message sent successfully!\033[0m')
        print(f'\033[0;36m📱 Message sent to chat ID: {chat_id}\033[0m')
    else:
        print(f'\033[0;31m❌ Failed to send test message: {response.status_code}\033[0m')
        print(f'\033[0;31m🔍 Response: {response.text}\033[0m')
        sys.exit(1)
        
except json.JSONDecodeError:
    print('\033[0;31m❌ Invalid JSON in config file\033[0m')
    sys.exit(1)
except requests.exceptions.RequestException as e:
    print(f'\033[0;31m❌ Network error: {e}\033[0m')
    sys.exit(1)
except Exception as e:
    print(f'\033[0;31m❌ Unexpected error: {e}\033[0m')
    sys.exit(1)
"
    read -p "Press Enter to continue..."
}

# 💾 Function to backup logs
backup_logs() {
    setup_dirs
    echo -e "${YELLOW}💾 Backing up logs...${NC}"
    
    if [ ! -d "$PROJECT_DIR/logs" ]; then
        echo -e "${RED}❌ Logs directory not found${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    backup_dir="$PROJECT_DIR/logs/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Copy log files
    log_count=0
    for log_file in "$PROJECT_DIR/logs/"*.log; do
        if [ -f "$log_file" ]; then
            cp "$log_file" "$backup_dir/"
            ((log_count++))
        fi
    done
    
    if [ $log_count -eq 0 ]; then
        echo -e "${YELLOW}⚠️ No log files found to backup${NC}"
        rmdir "$backup_dir" 2>/dev/null
    else
        echo -e "${GREEN}✅ $log_count log file(s) backed up to $backup_dir${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# 📊 Function to show project status
show_status() {
    setup_dirs
    echo -e "${YELLOW}📊 Checking project status...${NC}"
    echo "========================================"
    
    # Check project directory
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${GREEN}✅ Project directory: $PROJECT_DIR${NC}"
        
        # Check git status
        if [ -d "$PROJECT_DIR/.git" ]; then
            cd "$PROJECT_DIR"
            VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "Unknown")
            echo -e "${GREEN}✅ Git version: $VERSION${NC}"
        else
            echo -e "${YELLOW}⚠️ Not a git repository${NC}"
        fi
    else
        echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"
    fi
    
    # Check virtual environment
    if [ -d "$VENV_DIR" ]; then
        echo -e "${GREEN}✅ Virtual environment exists${NC}"
    else
        echo -e "${RED}❌ Virtual environment not found${NC}"
    fi
    
    # Check config file
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✅ Config file exists: $CONFIG_FILE${NC}"
        if jq empty "$CONFIG_FILE" 2>/dev/null; then
            echo -e "${GREEN}✅ Config file is valid JSON${NC}"
        else
            echo -e "${RED}❌ Config file has invalid JSON format${NC}"
        fi
    else
        echo -e "${RED}❌ Config file missing: $CONFIG_FILE${NC}"
    fi
    
    # Check service status
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        echo -e "${GREEN}✅ Service $SERVICE_NAME is enabled${NC}"
        
        if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
            echo -e "${GREEN}✅ Service $SERVICE_NAME is running${NC}"
            echo -e "${CYAN}📊 Service status:${NC}"
            sudo systemctl status "$SERVICE_NAME" --no-pager --lines=5
        else
            echo -e "${RED}❌ Service $SERVICE_NAME is not running${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Service $SERVICE_NAME is not enabled${NC}"
    fi
    
    echo "========================================"
    read -p "Press Enter to continue..."
}

# 🔍 Function to check dependencies
check_deps() {
    setup_dirs
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
    echo "========================================"
    
    # Check system dependencies
    echo -e "${CYAN}🖥️ System Dependencies:${NC}"
    for cmd in git python3 pip jq curl wget; do
        if command_exists "$cmd"; then
            version=$($cmd --version 2>/dev/null | head -n1 || echo "Unknown version")
            echo -e "${GREEN}✅ $cmd: $version${NC}"
        else
            echo -e "${RED}❌ $cmd is not installed${NC}"
        fi
    done
    
    # Check Python virtual environment
    echo -e "\n${CYAN}🐍 Python Virtual Environment:${NC}"
    if [ -d "$VENV_DIR" ]; then
        echo -e "${GREEN}✅ Virtual environment exists${NC}"
        source "$VENV_DIR/bin/activate"
        echo -e "${CYAN}📦 Installed packages:${NC}"
        pip list --format=columns 2>/dev/null || pip list
    else
        echo -e "${RED}❌ Virtual environment not found: $VENV_DIR${NC}"
    fi
    
    # Check network connectivity
    echo -e "\n${CYAN}🌐 Network Connectivity:${NC}"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Internet connection available${NC}"
    else
        echo -e "${RED}❌ No internet connection${NC}"
    fi
    
    # Check GitHub connectivity
    if curl -s --head https://github.com >/dev/null; then
        echo -e "${GREEN}✅ GitHub is accessible${NC}"
    else
        echo -e "${RED}❌ GitHub is not accessible${NC}"
    fi
    
    echo "========================================"
    read -p "Press Enter to continue..."
}

# 📋 Function to view logs
view_logs() {
    setup_dirs
    echo -e "${YELLOW}📋 Viewing logs...${NC}"
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${CYAN}📄 Install log (last 50 lines):${NC}"
        tail -n 50 "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️ Install log not found${NC}"
    fi
    
    echo -e "\n${CYAN}📊 Service logs (last 20 lines):${NC}"
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        sudo journalctl -u "$SERVICE_NAME" --no-pager -n 20
    else
        echo -e "${YELLOW}⚠️ Service not enabled${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# 🗑️ Function to remove project
remove_project() {
    setup_dirs
    echo -e "${YELLOW}🗑️ Removing kuma-monitoring-reporter...${NC}"
    echo -e "${RED}⚠️ This will completely remove the project and all its data!${NC}"
    read -p "Are you sure you want to continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}💡 Removal cancelled${NC}"
        read -p "Press Enter to continue..."
        return 0
    fi
    
    # Stop and disable service
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        echo -e "${CYAN}🛑 Stopping and disabling service...${NC}"
        if check_sudo; then
            sudo systemctl stop "$SERVICE_NAME" 2>/dev/null
            sudo systemctl disable "$SERVICE_NAME" 2>/dev/null
            sudo rm -f "$SERVICE_FILE"
            sudo systemctl daemon-reload 2>/dev/null
        fi
    fi
    
    # Remove project directory
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${CYAN}🗂️ Removing project directory...${NC}"
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}✅ Project directory removed${NC}"
    else
        echo -e "${YELLOW}⚠️ Project directory not found: $PROJECT_DIR${NC}"
    fi
    
    echo -e "${GREEN}🎉 Project removed successfully!${NC}"
    read -p "Press Enter to continue..."
}

# 🚀 Service Management Submenu
service_management() {
    while true; do
        clear
        echo -e "\n🌟 Service Management Menu"
        echo "-------------------------------------"
        echo "1. Setup systemd service 🛠️"
        echo "2. Start bot 🚀"
        echo "3. Stop bot 🛑"
        echo "4. Restart bot 🔄"
        echo "5. Show service status 📊"
        echo "6. View logs 📋"
        echo "0. Back to main menu ⬅️"
        echo "-------------------------------------"
        read -p "Choose an option: " sub_choice
        case $sub_choice in
            1) setup_service ;;
            2) 
                if check_sudo; then
                    sudo systemctl start "$SERVICE_NAME" && echo -e "${GREEN}✅ Bot started${NC}" || echo -e "${RED}❌ Failed to start bot${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3) stop_bot ;;
            4) restart_bot ;;
            5) show_status ;;
            6) view_logs ;;
            0) break ;;
            *) echo -e "${RED}❌ Invalid option${NC}"; read -p "Press Enter to continue..." ;;
        esac
    done
}

# 🔧 Tools submenu
tools_menu() {
    while true; do
        clear
        echo -e "\n🔧 Tools Menu"
        echo "-------------------------------------"
        echo "1. Test Telegram configuration 📬"
        echo "2. Backup logs 💾"
        echo "3. View logs 📋"
        echo "4. Check dependencies 🔍"
        echo "5. Validate config file ✅"
        echo "0. Back to main menu ⬅️"
        echo "-------------------------------------"
        read -p "Choose an option: " sub_choice
        case $sub_choice in
            1) test_telegram ;;
            2) backup_logs ;;
            3) view_logs ;;
            4) check_deps ;;
            5) 
                if [ -f "$CONFIG_FILE" ]; then
                    if jq empty "$CONFIG_FILE" 2>/dev/null; then
                        echo -e "${GREEN}✅ Config file is valid JSON${NC}"
                        echo -e "${CYAN}📄 Config content:${NC}"
                        jq . "$CONFIG_FILE"
                    else
                        echo -e "${RED}❌ Config file has invalid JSON format${NC}"
                    fi
                else
                    echo -e "${RED}❌ Config file not found${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            0) break ;;
            *) echo -e "${RED}❌ Invalid option${NC}"; read -p "Press Enter to continue..." ;;
        esac
    done
}

# 🎯 Function to show help
show_help() {
    clear
    echo -e "\n🎯 kuma-monitoring-reporter Help"
    echo "========================================"
    echo -e "${CYAN}📖 About:${NC}"
    echo "This script helps you install, configure, and manage the kuma-monitoring-reporter project."
    echo ""
    echo -e "${CYAN}🔧 Prerequisites:${NC}"
    echo "- Ubuntu/Debian Linux system"
    echo "- Internet connection"
    echo "- sudo privileges"
    echo ""
    echo -e "${CYAN}📋 Installation Steps:${NC}"
    echo "1. Install project (installs system deps + project)"
    echo "2. Configure config.json (set up Telegram bot + thresholds)"
    echo "3. Setup systemd service (run as background service)"
    echo ""
    echo -e "${CYAN}🛠️ Troubleshooting:${NC}"
    echo "- Check logs: Use 'View logs' option"
    echo "- Validate config: Use 'Tools' → 'Validate config file'"
    echo "- Test Telegram: Use 'Test Telegram configuration'"
    echo "- Check status: Use 'Show project status'"
    echo ""
    echo -e "${CYAN}📁 File Locations:${NC}"
    echo "- Project: $PROJECT_DIR"
    echo "- Config: $CONFIG_FILE"
    echo "- Logs: $PROJECT_DIR/logs/"
    echo "- Service: $SERVICE_FILE"
    echo ""
    echo -e "${CYAN}🔗 Useful Commands:${NC}"
    echo "- View service logs: sudo journalctl -u $SERVICE_NAME -f"
    echo "- Manual run: source $VENV_DIR/bin/activate && python3 report.py"
    echo "========================================"
    read -p "Press Enter to continue..."
}

# Signal handler for cleanup
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# 📋 Main Menu
while true; do
    clear
    echo -e "\n🌟 kuma-monitoring-reporter Installer v2.0"
    echo "=============================================="
    echo -e "${CYAN}Welcome to the installer! Choose an action:${NC}"
    echo ""
    echo "📦 Installation & Updates:"
    echo "  1. Install project 🚀"
    echo "  2. Update project 🔄"
    echo ""
    echo "⚙️ Configuration:"
    echo "  3. Configure config.json ⚙️"
    echo ""
    echo "🛠️ Management:"
    echo "  4. Service management 🛠️"
    echo "  5. Show project status 📊"
    echo ""
    echo "🔧 Tools:"
    echo "  6. Tools menu 🔧"
    echo ""
    echo "ℹ️ Other:"
    echo "  7. Help 🎯"
    echo "  8. Completely remove project 🗑️"
    echo "  0. Exit ⬅️"
    echo "=============================================="
    read -p "Choose an option [0-8]: " choice

    case $choice in
        1) install_system_deps && install_project ;;
        2) update_project ;;
        3) configure_json ;;
        4) service_management ;;
        5) show_status ;;
        6) tools_menu ;;
        7) show_help ;;
        8) remove_project ;;
        0) 
            clear
            echo -e "${GREEN}🎉 Thanks for using kuma-monitoring-reporter installer!${NC}"
            echo -e "${CYAN}💡 For support, visit: https://github.com/power0matin/kuma-monitoring-reporter${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}❌ Invalid option. Please choose 0-8.${NC}"
            read -p "Press Enter to continue..." 
            ;;
    esac
done