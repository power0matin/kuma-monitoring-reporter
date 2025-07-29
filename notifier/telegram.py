import json
import requests


def load_config():
    with open("config/config.json", "r") as config_file:
        return json.load(config_file)


def send_message(message):
    config = load_config()
    bot_token = config["telegram_bot_token"]
    chat_id = config["telegram_chat_id"]
    notification_mode = config.get("notification_mode", "sound")

    disable_notification = notification_mode == "silent"

    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "Markdown",
        "disable_notification": disable_notification,
    }

    response = requests.post(url, json=payload)
    if response.status_code != 200:
        with open("logs/error.log", "a") as log_file:
            log_file.write(f"Failed to send Telegram message: {response.text}\n")
        return False
    return True
