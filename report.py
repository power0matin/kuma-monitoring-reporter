import schedule
import time
import logging
from core.fetch import fetch_metrics
from core.formatter import format_report
from core.telegram import send_message, load_config

# Setup logging
logging.basicConfig(
    filename="logs/error.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def main():
    try:
        config = load_config()
        logging.debug(f"Config loaded: {config}")
        metrics = fetch_metrics(config["kuma_url"], config.get("auth_token"))
        logging.debug(f"Metrics fetched: {metrics}")
        report = format_report(metrics, config["thresholds"])
        logging.debug(f"Report formatted: {report}")
        success = send_message(report, silent=True)  # Send messages silently
        if success:
            logging.info("Report sent successfully to Telegram")
        else:
            logging.error("Failed to send report to Telegram")
    except Exception as e:
        logging.error(f"Error in main loop: {str(e)}", exc_info=True)


def run():
    try:
        config = load_config()
        schedule.every(config["report_interval"]).minutes.do(main)
        logging.info("Starting Kuma Monitoring Reporter")
        main()  # Run immediately for testing
        while True:
            schedule.run_pending()
            time.sleep(60)
    except Exception as e:
        logging.error(f"Error in run loop: {str(e)}", exc_info=True)
        raise


if __name__ == "__main__":
    run()
