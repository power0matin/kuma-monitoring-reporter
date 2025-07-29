import json
import schedule
import time
import os
import logging
from core.fetcher import fetch_metrics
from core.formatter import format_message
from notifier.telegram import send_telegram_message

logging.basicConfig(
    filename="logs/error.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def load_config():
    """Load configuration from config.json."""
    config_path = "config/config.json"
    if not os.path.exists(config_path):
        logging.error("Config file not found: config/config.json")
        exit(1)
    with open(config_path, "r") as f:
        return json.load(f)


def main():
    """Main function to fetch, format, and send reports."""
    config = load_config()
    metrics = fetch_metrics(config)  # Pass the entire config dictionary
    if metrics:
        message = format_message(metrics, config["thresholds"])
        if message:
            if send_telegram_message(config, message):
                logging.info("Report sent successfully.")
            else:
                logging.error("Failed to send report.")
        else:
            logging.debug("No changes in metrics, no report sent.")
    else:
        logging.warning("No metrics fetched, skipping report.")


if __name__ == "__main__":
    config = load_config()
    schedule.every(config["report_interval"]).minutes.do(main)
    logging.info(
        f"Bot started. Reports will be sent every {config['report_interval']} minute(s)."
    )
    main()  # Run once immediately
    while True:
        schedule.run_pending()
        time.sleep(1)
