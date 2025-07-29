import json
import logging
import time
import schedule

from core.fetcher import fetch_metrics
from core.parser import parse_prometheus_metrics
from core.formatter import format_message
from notifier.telegram import send_telegram_message

logging.basicConfig(
    filename="logs/error.log",
    level=logging.ERROR,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


def load_config():
    with open("config/config.json") as f:
        return json.load(f)


def main():
    config = load_config()
    try:
        raw_metrics = fetch_metrics(config["kuma_url"], config["auth_token"])
        metrics = parse_prometheus_metrics(raw_metrics)
        message = format_message(metrics, config["thresholds"])
        send_telegram_message(
            config["telegram_bot_token"], config["telegram_chat_id"], message
        )
    except Exception as e:
        logging.error(f"Error in main: {e}")
        print(f"[!] Error: {e}")


def job():
    main()


if __name__ == "__main__":
    job()  # اجرای فوری
    schedule.every(30).minutes.do(job)

    while True:
        schedule.run_pending()
        time.sleep(1)
