from collections import defaultdict


def parse_prometheus_metrics(text):
    metrics = defaultdict(list)

    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        if "{" in line:
            name = line[: line.index("{")]
            labels_text = line[line.index("{") + 1 : line.index("}")]
            value = line[line.index("}") + 1 :].strip()

            labels = dict(label.split("=") for label in labels_text.split(","))
            labels = {k: v.strip('"') for k, v in labels.items()}
            metrics[name].append((labels, float(value)))
    return metrics
