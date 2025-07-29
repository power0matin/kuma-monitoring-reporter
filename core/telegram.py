import json
import requests
import logging

# Setup logging
logging.basicConfig(
    filename="logs/error.log",
    level=logging.DEBUG,
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


def send_message(message, silent=False):
    config = load_config()
    bot_token = config.get("telegram_bot_token")
    chat_id = config.get("telegram_chat_id")

    if not bot_token or not chat_id:
        logging.error("Missing telegram_bot_token or telegram_chat_id in config.json")
        raise ValueError("Invalid Telegram configuration")

    # Escape special characters for MarkdownV2
    special_chars = [
        "_",
        "*",
        "[",
        "]",
        "(",
        ")",
        "~",
        "`",
        ">",
        "#",
        "+",
        "-",
        "=",
        "|",
        "{",
        "}",
        ".",
        "!",
    ]
    for char in special_chars:
        message = message.replace(char, f"\\{char}")

    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": message,
        "parse_mode": "MarkdownV2",
        "disable_notification": silent,  # Set to True for silent messages
    }

    try:
        response = requests.post(url, json=payload, timeout=10)
        response.raise_for_status()
        logging.info(f"Message sent successfully. Silent: {silent}")
        return True
    except requests.RequestException as e:
        logging.error(
            f"Failed to send Telegram message: {str(e)} - Response: {response.text}"
        )
        return False
