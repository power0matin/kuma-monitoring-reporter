from prometheus_client.parser import text_string_to_metric_families


def parse_prometheus_metrics(raw_metrics):
    """Parse Prometheus metrics into a structured format."""
    metrics = {"monitor_response_time": [], "monitor_status": [], "monitor_msg": []}
    try:
        for family in text_string_to_metric_families(raw_metrics):
            for sample in family.samples:
                labels = sample[1]
                value = sample[2]
                if family.name == "monitor_response_time":
                    metrics["monitor_response_time"].append((labels, value))
                elif family.name == "monitor_status":
                    metrics["monitor_status"].append((labels, value))
                elif family.name == "monitor_msg":
                    metrics["monitor_msg"].append((labels, value))
    except Exception as e:
        print(f"Error parsing metrics: {e}")
    return metrics
