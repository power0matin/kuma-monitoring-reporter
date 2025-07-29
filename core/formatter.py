from datetime import datetime


def format_message(metrics, thresholds):
    """Format metrics into a Telegram message."""
    if not metrics:
        return None

    msg_lines = [
        "📊 *Uptime Kuma Status Report*",
        f"🕒 *Time*: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "════════════════════════════",
    ]

    up_count = 0
    down_count = 0

    for metric in metrics:
        name = metric["name"]
        monitor_type = metric["type"]
        status = metric["status"]
        response_ms = metric["response_ms"]
        if response_ms < 1:
            response_ms = 0.0  # Round very small values to 0.0
        else:
            response_ms = round(response_ms, 1)  # Round to 1 decimal place

        if status == "DOWN":
            emoji = "🔴"
            down_count += 1
            line = f"{emoji} *{name}* ({monitor_type}) is *DOWN*"
        else:
            up_count += 1
            if response_ms < thresholds["good"]:
                emoji = "🟢"
            elif response_ms < thresholds["warning"]:
                emoji = "🟡"
            else:
                emoji = "🔴"
            line = f"{emoji} *{name}* ({monitor_type}) — `{response_ms:.1f} ms`"
        msg_lines.append(line)

    msg_lines.append("════════════════════════════")
    msg_lines.append(f"📈 *Summary*: {up_count} UP, {down_count} DOWN")
    return "\n".join(msg_lines)
