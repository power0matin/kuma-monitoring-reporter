# توی core/formatter.py
last_statuses = {}  # برای ذخیره وضعیت قبلی مانیتورها

def format_message(metrics, thresholds):
    global last_statuses
    response_times = metrics.get("monitor_response_time", [])
    statuses = {
        labels["monitor_name"]: value
        for labels, value in metrics.get("monitor_status", [])
    }
    msg_lines = ["📊 *Uptime Kuma Status Report*"]

    changed = False
    for labels, response_time in response_times:
        name = labels.get("monitor_name", "Unknown")
        status = statuses.get(name, 0)
        current_state = (status, response_time)

        # فقط اگه وضعیت تغییر کرده، اضافه کن
        if name not in last_statuses or last_statuses[name] != current_state:
            changed = True
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

    last_statuses = {labels["monitor_name"]: (statuses.get(labels["monitor_name"], 0), response_time) for labels, response_time in response_times}
    if not changed:  # اگه هیچ تغییری نبود، پیامی نفرست
        return None
    return "\n".join(msg_lines)