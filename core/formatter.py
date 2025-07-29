def format_message(metrics, thresholds):
    response_times = metrics.get("monitor_response_time", [])
    statuses = {
        labels["monitor_name"]: value
        for labels, value in metrics.get("monitor_status", [])
    }

    msg_lines = ["📊 *Uptime Kuma Status Report*"]

    for labels, response_time in response_times:
        name = labels.get("monitor_name", "Unknown")
        status = statuses.get(name, 0)

        if status == 0:
            emoji = "🔴"
            line = f"{emoji} *{name}* is *DOWN*"
        else:
            if response_time < thresholds["good"]:
                emoji = "🟢"
            elif response_time < thresholds["warning"]:
                emoji = "🟡"
            else:
                emoji = "🔴"

            line = f"{emoji} *{name}* — `{response_time:.1f} ms`"
        msg_lines.append(line)

    return "\n".join(msg_lines)
