import json
import schedule
import time
import os
from core.fetch import fetch_metrics
from core.parser import parse_prometheus_metrics
from core.formatter import format_message
from notifier.telegram import send_telegram_message


def load_config():
    """Load configuration from config.json."""
    config_path = "config/config.json"
    if not os.path.exists(config_path):
        print("Config file not found: config/config.json")
        exit(1)
    with open(config_path, "r") as f:
        return json.load(f)


def main():
    """Main function to fetch, parse, format, and send reports."""
    config = load_config()
    raw_metrics = fetch_metrics(config)
    if raw_metrics:
        metrics = parse_prometheus_metrics(raw_metrics)
        message = format_message(metrics, config["thresholds"])
        if message:
            if send_telegram_message(config, message):
                print("Report sent successfully.")
            else:
                print("Failed to send report.")


if __name__ == "__main__":
    config = load_config()
    schedule.every(config["report_interval"]).minutes.do(main)
    print(
        f"Bot started. Reports will be sent every {config['report_interval']} minute(s)."
    )
    main()  # Run once immediately
    while True:
        schedule.run_pending()
        time.sleep(1)
