from datetime import datetime

last_statuses = {}  # برای ذخیره وضعیت قبلی مانیتورها

def format_message(metrics, thresholds):
    global last_statuses
    response_times = metrics.get("monitor_response_time", [])
    statuses = {labels["monitor_name"]: value for labels, value in metrics.get("monitor_status", [])}
    messages = metrics.get("monitor_msg", [])  # پیام‌های خطا یا وضعیت
    monitor_types = {labels["monitor_name"]: labels.get("monitor_type", "Unknown") for labels, _ in response_times}
    
    msg_lines = [
        "📊 *Uptime Kuma Status Report*",
        f"🕒 *Time*: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "════════════════════════════"
    ]

    changed = False
    up_count = 0
    down_count = 0

    for labels, response_time in response_times:
        name = labels.get("monitor_name", "Unknown")
        monitor_type = monitor_types.get(name, "Unknown")
        status = statuses.get(name, 0)
        error_msg = next((m[1] for m in messages if m[0].get("monitor_name") == name), None)
        current_state = (status, response_time, error_msg)

        # فقط اگه وضعیت تغییر کرده، اضافه کن
        if name not in last_statuses or last_statuses[name] != current_state:
            changed = True
            if status == 0:
                emoji = "🔴"
                down_count += 1
                line = f"{emoji} *{name}* ({monitor_type}) is *DOWN*"
                if error_msg:
                    line += f" — Reason: `{error_msg}`"
            else:
                up_count += 1
                if response_time < thresholds["good"]:
                    emoji = "🟢"
                elif response_time < thresholds["warning"]:
                    emoji = "🟡"
                else:
                    emoji = "🔴"
                line = f"{emoji} *{name}* ({monitor_type}) — `{response_time:.1f} ms`"
            msg_lines.append(line)

    last_statuses = {
        labels["monitor_name"]: (
            statuses.get(labels["monitor_name"], 0),
            response_time,
            next((m[1] for m in messages if m[0].get("monitor_name") == labels["monitor_name"]), None)
        )
        for labels, response_time in response_times
    }

    # اضافه کردن خلاصه وضعیت
    msg_lines.append("════════════════════════════")
    msg_lines.append(f"📈 *Summary*: {up_count} UP, {down_count} DOWN")

    if not changed:
        return None  # اگه تغییری نبود، پیامی نفرست
    return "\n".join(msg_lines)