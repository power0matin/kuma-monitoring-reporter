import schedule
import time
import logging
from core.fetcher import fetch_metrics
from core.formatter import format_message
from notifier.telegram import send_message, load_config

# Setup logging
logging.basicConfig(filename='logs/error.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def main():
    try:
        config = load_config()
        metrics = fetch_metrics(config["kuma_url"], config.get("auth_token"))
        report = format_message(metrics, config["thresholds"])
        success = send_message(report, silent=True)  # Send messages silently
        if success:
            logging.info("Report sent successfully to Telegram")
        else:
            logging.error("Failed to send report to Telegram")
    except Exception as e:
        logging.error(f"Error in main loop: {str(e)}")

def run():
    try:
        config = load_config()
        schedule.every(config["report_interval"]).minutes.do(main)
        logging.info("Starting Kuma Monitoring Reporter")
        while True:
            schedule.run_pending()
            time.sleep(60)
    except Exception as e:
        logging.error(f"Error in run loop: {str(e)}")
        raise

if __name__ == "__main__":
    run()