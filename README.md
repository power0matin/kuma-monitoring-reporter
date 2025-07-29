# 📡 Kuma Monitoring Reporter

A lightweight, modular tool to monitor [Uptime Kuma](https://github.com/louislam/uptime-kuma) metrics and send beautifully formatted status reports to Telegram. Stay informed about your services with real-time updates and customizable thresholds.

## ✨ Features

- 🛠 **Modular Design**: Cleanly separated modules for fetching, formatting, and sending data.
- 📝 **Formatted Reports**: Markdown-based Telegram messages with emojis (🟢🟡🔴) for clear status visualization.
- ⚙️ **Easy Configuration**: Interactive setup via `install.sh` or manual editing of `config/config.json`.
- 📡 **Multi-Monitor Support**: Handles various monitor types (HTTP, ping, port, group, etc.).
- 🔔 **Customizable Notifications**: Choose between sound or silent Telegram notifications.
- 🔄 **Systemd Integration**: Run the bot as a persistent service with start, stop, and restart options.
- 🛡️ **Error Handling**: Detailed logging with backup capabilities for debugging.
- ✅ **Interactive Management**: Comprehensive `install.sh` script for installation, updates, and maintenance.
- 🔐 **Secure API Access**: Supports Uptime Kuma’s read-only API tokens.

## 📋 Prerequisites

- **Operating System**: Linux (tested on Ubuntu)
- **Dependencies**:
  - Git: `sudo apt-get install git`
  - Python 3: `sudo apt-get install python3`
  - pip3: `sudo apt-get install python3-pip`
  - Systemd: `sudo apt-get install systemd`
  - jq (for Telegram testing): `sudo apt-get install jq`
- **Python Packages** (listed in `requirements.txt`):
  - `requests`
  - `schedule`
  - `prometheus_client`
- **Uptime Kuma**: A running instance with an accessible `/metrics` endpoint.
- **Telegram**: A bot token from [@BotFather](https://t.me/BotFather) and a chat ID.

## 🚀 Installation

### 🔧 Option 1: Automatic Installation (Recommended)

Run the installer script to set up the project interactively:

```bash
bash <(curl -s https://raw.githubusercontent.com/power0matin/kuma-monitoring-reporter/main/install.sh)
```

The script provides a menu with options to:

- Clone the repository
- Set up a Python virtual environment
- Install dependencies
- Configure `config.json` interactively
- Manage the bot as a systemd service
- Test Telegram settings, back up logs, and more

### 🛠 Option 2: Manual Installation (Advanced)

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/power0matin/kuma-monitoring-reporter.git
   cd kuma-monitoring-reporter
   ```

2. **Set Up Virtual Environment**:

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install Dependencies**:

   ```bash
   pip install -r requirements.txt
   ```

4. **Configure the Project**:
   Edit `config/config.json`:

   ```bash
   nano config/config.json
   ```

   Example configuration:

   ```json
   {
     "kuma_url": "http://your-server:3001/metrics",
     "telegram_bot_token": "1234567890:AAH...",
     "telegram_chat_id": "123456789",
     "auth_token": "",
     "thresholds": {
       "good": 200,
       "warning": 500,
       "critical": 1000
     },
     "report_interval": 1,
     "notification_mode": "sound"
   }
   ```

   > 🔐 Use a **Read-Only API Token** from Uptime Kuma if authentication is required.

5. **Run the Reporter**:
   ```bash
   python3 report.py
   ```

## 📬 Sample Report

Reports are sent to your Telegram chat at the configured interval (e.g., every minute):

```
Uptime Kuma Status Report
Time: 2025-07-29 13:55:00
════════════════════════════
🟢 Germany_hetzner (http) — 0.0 ms
🟡 Iran-0-1 (ping) — 78.0 ms
🟡 Iran-respina (http) — 86.0 ms
════════════════════════════
Summary: 3 UP, 0 DOWN
```

## ⚙️ Project Structure

| File/Directory       | Description                                 |
| -------------------- | ------------------------------------------- |
| `report.py`          | Main script to run the reporter             |
| `core/fetch.py`      | Fetches metrics from Uptime Kuma API        |
| `core/formatter.py`  | Processes and formats data for reports      |
| `core/telegram.py`   | Sends messages to Telegram                  |
| `config/config.json` | Configuration file for the project          |
| `logs/error.log`     | Error logs for debugging                    |
| `install.sh`         | Interactive script for setup and management |

## 🛠 Usage Instructions

Run the installer script to manage the project:

```bash
cd ~/kuma-monitoring-reporter
./install.sh
```

The script offers a menu-driven interface for easy management. Below are the available options:

<details>
<summary>📖 Click to view detailed usage instructions for install.sh</summary>

- **1. Install project**:

  - Clones the repository to `~/kuma-monitoring-reporter`.
  - Creates a Python virtual environment and installs dependencies.
  - Use for initial setup.
  - Example: Select this to install the project from scratch.

- **2. Configure config.json file**:

  - Prompts for Kuma URL, Telegram bot token, chat ID, API token, thresholds, report interval, and notification mode (sound/silent).
  - Saves settings to `config/config.json`.
  - Example: Use to set up or update bot configuration.

- **3. Update project**:

  - Pulls the latest changes from GitHub (`git pull origin main`).
  - Updates Python dependencies.
  - Example: Use to keep the project up-to-date.

- **4. Service management**:

  - **4.1 Start systemd service**:
    - Sets up and starts a systemd service (`kuma-reporter.service`) for persistent operation.
    - Overwrites existing service if confirmed.
  - **4.2 Stop bot**:
    - Stops the systemd service or terminates manual bot processes.
    - Optionally disables the systemd service.
  - **4.3 Restart systemd service**:
    - Restarts the systemd service if it exists.
  - Example: Use to manage the bot’s execution.

- **5. Test Telegram configuration**:

  - Sends a test message to verify Telegram bot token and chat ID.
  - Requires `jq` to parse `config.json`.
  - Example: Use to confirm Telegram settings.

- **6. Backup logs**:

  - Compresses `logs/error.log` into a timestamped tar.gz file in `/tmp/kuma-backup`.
  - Example: Use to save logs for debugging.

- **7. Show project status**:

  - Displays project directory, Git version, `config.json` contents, systemd service status, and running processes.
  - Example: Use to check the project’s current state.

- **8. Check dependencies**:

  - Verifies and installs Python dependencies from `requirements.txt`.
  - Example: Use if you suspect missing packages.

- **9. Completely remove project**:

  - Deletes the project directory (`~/kuma-monitoring-reporter`).
  - Optionally backs up `config.json` to `/tmp/kuma-backup`.
  - Stops and removes the systemd service if it exists.
  - Example: Use to uninstall the project.

- **0. Exit**:
  - Closes the installer script.
  </details>

## 🛡️ Troubleshooting

- **No Telegram Reports**:
  - Run Option 5 (Test Telegram configuration) to verify bot token and chat ID.
  - Check `logs/error.log` for errors:
    ```bash
    cat ~/kuma-monitoring-reporter/logs/error.log
    ```
- **Systemd Service Issues**:
  - Check service status:
    ```bash
    sudo systemctl status kuma-reporter.service
    ```
  - Restart the service using Option 4.3.
- **Dependency Errors**:
  - Run Option 8 (Check dependencies) to ensure all packages are installed.
- **Invalid Configuration**:
  - Verify `config.json` fields, especially `kuma_url`, `telegram_bot_token`, and `telegram_chat_id`.
  - Use Option 2 to reconfigure.

## 🌟 Future Development Ideas

- [ ] Add support for filtering monitors by tags or names.
- [ ] Implement selective reporting for problematic monitors only.
- [ ] Add support for multiple Telegram channels or other platforms (e.g., Discord, Slack).
- [ ] Introduce interactive Telegram buttons (e.g., Pause/Resume monitoring).
- [ ] Enhance logging with structured formats (e.g., JSON logs).
- [ ] Add support for custom report templates.

## 🙌 Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature`.
3. Commit changes: `git commit -m "Add your feature"`.
4. Push to the branch: `git push origin feature/your-feature`.
5. Open a pull request.

Please include clear descriptions of your changes and test thoroughly.

## 📜 License

This project is licensed under the [MIT License](LICENSE).

## 📦 Requirements

The `requirements.txt` file includes:

```txt
requests
schedule
prometheus_client
```

## 📅 Project Roadmap

### 🔹 Phase 1: MVP (Completed)

- Fetch data from Uptime Kuma API.
- Format and send reports to Telegram.
- Basic JSON configuration.

### 🔹 Phase 2: Modularization (Completed)

- Structured modules (`fetch.py`, `formatter.py`, `telegram.py`).
- Error handling and logging.
- Interactive `install.sh` script.

### 🔹 Phase 3: Enhanced Features (In Progress)

- Systemd service management.
- Silent/sound notification modes.
- Log backup and status reporting.

### 🔹 Phase 4: Advanced Features & Publishing

- Add filtering and selective reporting.
- Support for interactive Telegram buttons.
- Comprehensive documentation and GitHub Actions for CI/CD.

## 📬 Contact

For suggestions or issues, open a ticket on the [GitHub repository](https://github.com/power0matin/kuma-monitoring-reporter) or contact the maintainer.