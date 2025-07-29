import requests
import logging

logging.basicConfig(filename='logs/error.log', level=logging.DEBUG, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def fetch_metrics(kuma_url, auth_token=None):
    try:
        headers = {"Authorization": f"Bearer {auth_token}"} if auth_token else {}
        response = requests.get(kuma_url, headers=headers, timeout=10)
        response.raise_for_status()
        metrics = response.text.splitlines()
        parsed_metrics = []
        for line in metrics:
            if line.startswith("uptimekuma_monitor"):
                # Parse example: uptimekuma_monitor_info{monitor_name="Germany_hetzner",monitor_type="ping"} 1
                # or uptimekuma_monitor_response_ms{monitor_name="Germany_hetzner"} 0
                if "monitor_name" in line:
                    name = line.split('monitor_name="')[1].split('"')[0]
                    if "monitor_type" in line:
                        monitor_type = line.split('monitor_type="')[1].split('"')[0]
                        parsed_metrics.append({"name": name, "type": monitor_type, "status": "UP", "response_ms": 0})
                    elif "response_ms" in line:
                        response_ms = float(line.split('} ')[1])
                        for metric in parsed_metrics:
                            if metric["name"] == name:
                                metric["response_ms"] = response_ms
        logging.debug(f"Fetched metrics: {parsed_metrics}")
        return parsed_metrics
    except requests.RequestException as e:
        logging.error(f"Failed to fetch metrics from {kuma_url}: {str(e)}")
        raise