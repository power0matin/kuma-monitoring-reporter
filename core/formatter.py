import logging
from datetime import datetime

logging.basicConfig(
    filename="logs/error.log",
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def format_report(metrics, thresholds):
    try:
        report = f"📊 Uptime Kuma Status Report\n🕒 Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n════════════════════════════\n"
        up_count = 0
        down_count = 0
        for monitor in metrics:
            name = monitor["name"]
            monitor_type = monitor["type"]
            response_ms = monitor["response_ms"]
            status = monitor["status"]
            if status == "UP":
                up_count += 1
                if response_ms <= thresholds["good"]:
                    emoji = "🟢"
                elif response_ms <= thresholds["warning"]:
                    emoji = "🟡"
                else:
                    emoji = "🔴"
            else:
                down_count += 1
                emoji = "🔴"
            report += f"{emoji} {name} ({monitor_type}) — {response_ms:.1f} ms\n"
        report += "════════════════════════════\n"
        report += f"📈 Summary: {up_count} UP, {down_count} DOWN"
        logging.debug(f"Formatted report: {report}")
        return report
    except Exception as e:
        logging.error(f"Failed to format report: {str(e)}")
        raise
