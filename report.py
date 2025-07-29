import json
from core.fetcher import fetch_metrics
from core.parser import parse_prometheus_metrics
from core.formatter import format_message
from notifier.telegram import send_telegram_message


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
        print(f"[!] Error: {e}")


if __name__ == "__main__":
    main()
