import requests
import logging
import os


def setup_logging():
    """Set up logging with automatic creation of logs directory and error.log file."""
    log_dir = "logs"
    log_file = os.path.join(log_dir, "error.log")

    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    if not os.path.exists(log_file):
        open(log_file, "a").close()

    logging.basicConfig(
        filename=log_file,
        level=logging.DEBUG,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )


def fetch_metrics(config):
    """Fetch and parse metrics from Uptime Kuma's /metrics endpoint."""
    setup_logging()
    kuma_url = config["kuma_url"]
    auth_token = config.get("auth_token")

    try:
        auth = ("", auth_token) if auth_token else None
        response = requests.get(kuma_url, auth=auth, timeout=10)
        response.raise_for_status()

        metrics = response.text.splitlines()
        parsed_metrics = {}

        for line in metrics:
            if line.startswith("#") or not line:
                continue
            if "monitor_" in line:
                parts = line.split("{")
                metric_name = parts[0]
                labels_str = parts[1].split("}")[0]
                value = float(parts[1].split("} ")[1])

                labels = {}
                for label in labels_str.split(","):
                    key, val = label.split("=")
                    labels[key.strip()] = val.strip('"')

                monitor_name = labels.get("monitor_name")
                if not monitor_name:
                    continue

                if monitor_name not in parsed_metrics:
                    parsed_metrics[monitor_name] = {
                        "name": monitor_name,
                        "type": labels.get("monitor_type", "unknown"),
                        "status": "UNKNOWN",
                        "response_ms": 0,
                    }

                if metric_name == "monitor_status":
                    parsed_metrics[monitor_name]["status"] = (
                        "UP"
                        if value == 1
                        else (
                            "DOWN"
                            if value == 0
                            else "PENDING" if value == 2 else "MAINTENANCE"
                        )
                    )
                elif metric_name == "monitor_response_time":
                    parsed_metrics[monitor_name]["response_ms"] = value

        parsed_metrics = list(parsed_metrics.values())
        logging.debug(f"Fetched metrics: {parsed_metrics}")
        return parsed_metrics

    except requests.RequestException as e:
        logging.error(f"Failed to fetch metrics from {kuma_url}: {str(e)}")
        return None
