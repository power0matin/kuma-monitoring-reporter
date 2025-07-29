# 📡 Kuma monitoring Reporter

Monitoring monitoring reporter from Uptime Kuma to Telegram — simple, beautiful and modular.

## ✨ Features

- 🛠 Fully modular and extensible
- ✅ Well-formatted Markdown messages
- 🟢🟡🔴 monitoring display with emoji based on response speed
- 🔐 Easy configuration via `config/config.json`
- 📡 Support for various monitors (ping, http, port, group, etc.)

## 🚀 Installation Guide

### 🔧 1. Automatic Install (Recommended)

```bash
bash <(curl -s https://raw.githubusercontent.com/power0matin/kuma-monitoring-reporter/main/install.sh)
```

The installation script includes:

- Clone the project
- Install the required packages
- Configure the `config.json` file interactively
- Ready to run

### 🛠 2. Manual Setup (Advanced)

#### 📥 Clone the repository

```bash
git clone https://github.com/power0matin/kuma-monitoring-reporter.git
cd kuma-monitoring-reporter
```

#### 📦 Install dependencies

```bash
pip3 install -r requirements.txt
```

#### ⚙️ Configuration

Edit the configuration file:

```bash
nano config/config.json
```

Paste and modify your values:

```json
{
  "kuma_url": "http://localhost:3001/metrics",
  "telegram_bot_token": "YOUR_TELEGRAM_BOT_TOKEN",
  "telegram_chat_id": "YOUR_CHAT_ID",
  "auth_token": "YOUR_KUMA_API_TOKEN",
  "thresholds": {
    "good": 0,
    "warning": 100,
    "critical": 200
  }
}
```

> 🔐 Use a **Read-Only API Token** from Uptime Kuma.

### ▶️ 3. Run the Reporter

```bash
python3 report.py
```

## ⚙️ Module Structure

| File                | Role                               |
| ------------------- | ---------------------------------- |
| `report.py`         | Main execution file                |
| `core/fetch.py`     | Fetch data from Kuma Uptime API    |
| `core/formatter.py` | Data processing and beautification |
| `core/sender.py`    | Send Telegram message              |

## 💡 Ideas for future development

- [ ] Scheduled automatic sending with cronjob or systemd timer
- [ ] Send only problematic monitors
- [ ] Filter monitors by tag or name
- [ ] Support for multiple Telegram channels
- [ ] Send to Discord or Slack

## 🪪 License

This project is released under the MIT license. See the [`LICENSE`](LICENSE) file.

## 🙌 Contributions

Funding requests and suggestions are most welcome.

## 📂 `requirements.txt` file

```txt
requests
```

## ✅ Project development phasing

### 🔹 Phase 1 — MVP (Minimum Viable Product)

- Receiving data from API
- Processing and formatting messages
- Sending to Telegram
- JSON configuration

### 🔹 Phase 2 — Development and modularization

- Complete structuring of modules
- Separating `fetch`, `formatter`, `sender`
- Checking for errors and clear messages

### 🔹 Phase 3 — More features

- Filtering by status or response time
- Sending messages only if there is an error
- Scheduling automatic execution (with `cron` or `systemd timer`)

### 🔹 Phase 4 — Publishing and documentation

- Preparing a professional README
- Uploading to GitHub
- Installation instructions in README
- Using Secrets for GitHub Actions in the future (Optional)
