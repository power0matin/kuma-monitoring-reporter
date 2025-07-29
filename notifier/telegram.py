import json
import requests
import logging
import os


os.makedirs("logs", exist_ok=True)


# Setup logging
logging.basicConfig(
    filename="logs/error.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def load_config():
    try:
        with open("config/config.json", "r") as config_file:
            config = json.load(config_file)
            logging.info("Successfully loaded config.json")
            return config
    except Exception as e:
        logging.error(f"Failed to load config.json: {str(e)}")
        raise


def send_telegram_message(message, test_mode=False):
    config = load_config()
    bot_token = config.get("telegram_bot_token")
    chat_id = config.get("telegram_chat_id")
    notification_mode = config.get("notification_mode", "sound")

    if not bot_token or not chat_id:
        logging.error("Missing telegram_bot_token or telegram_chat_id in config.json")
        raise ValueError("Invalid Telegram configuration")

    disable_notification = notification_mode == "silent"
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "MarkdownV2",  # Updated to MarkdownV2 for better formatting
        "disable_notification": disable_notification,
    }

    try:
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
        logging.info(f"Message sent successfully. Silent mode: {disable_notification}")
        if test_mode:
            return {"status": "success", "silent": disable_notification}
        return True
    except requests.RequestException as e:
        logging.error(
            f"Failed to send Telegram message: {str(e)} - Response: {response.text}"
        )
        if test_mode:
            return {"status": "failed", "error": str(e), "silent": disable_notification}
        return False


def test_telegram_notification():
    test_message = "Test message from Kuma Monitoring Reporter"
    result = send_telegram_message(test_message, test_mode=True)
    return result
