import json
import logging
import time
import schedule
import os
from notifier.telegram import send_telegram_message


from core.fetcher import fetch_metrics
from core.parser import parse_prometheus_metrics
from core.formatter import format_message
from notifier.telegram import send_telegram_message

# ایجاد پوشه logs اگه وجود نداشته باشه
os.makedirs("logs", exist_ok=True)

logging.basicConfig(
    filename="logs/error.log",
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


def load_config():
    logging.info("Loading config file...")
    with open("config/config.json") as f:
        config = json.load(f)
        logging.info("Config loaded successfully")
        return config


def main():
    config = load_config()
    logging.info("Starting main job...")
    try:
        raw_metrics = fetch_metrics(config["kuma_url"], config["auth_token"])
        logging.info(f"Fetched raw metrics: {raw_metrics[:100]}...")
        metrics = parse_prometheus_metrics(raw_metrics)
        logging.info(f"Parsed metrics: {metrics}")
        message = format_message(metrics, config["thresholds"])
        logging.info(f"Formatted message: {message}")
        send_telegram_message(message)
        logging.info("Message sent successfully")
    except Exception as e:
        logging.error(f"Error in main: {e}")
        send_telegram_message(
            config["telegram_bot_token"],
            config["telegram_chat_id"],
            f"❌ Error occurred: {str(e)}",
        )
        print(f"[!] Error: {e}")


def job():
    main()


if __name__ == "__main__":
    logging.info("Starting script...")
    config = load_config()
    job()  # اجرای فوری برای تست
    schedule.every(config["report_interval"]).minutes.do(
        job
    )  # استفاده از report_interval

    while True:
        schedule.run_pending()
        time.sleep(1)
