import requests


def fetch_metrics(config):
    """Fetch metrics from Uptime Kuma's /metrics endpoint."""
    url = config["kuma_url"]
    headers = (
        {"Authorization": f"Bearer {config['auth_token']}"}
        if config["auth_token"]
        else {}
    )
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        print(f"Error fetching metrics: {e}")
        return None
