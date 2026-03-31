#!/usr/bin/env python3
"""Pattern 2: Sparkline gauge - vertical block characters"""
import json, sys, datetime

data = json.load(sys.stdin)

SPARKS = ' ▁▂▃▄▅▆▇█'
R = '\033[0m'
DIM = '\033[2m'

def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f'\033[38;2;{r};200;80m'
    else:
        g = int(200 - (pct - 50) * 4)
        return f'\033[38;2;255;{max(g, 0)};60m'

def spark_gauge(pct, width=8):
    pct = min(max(pct, 0), 100)
    level = pct / 100
    gauge = ''
    for i in range(width):
        seg_start = i / width
        seg_end = (i + 1) / width
        if level >= seg_end:
            gauge += SPARKS[8]
        elif level <= seg_start:
            gauge += SPARKS[0]
        else:
            frac = (level - seg_start) / (seg_end - seg_start)
            gauge += SPARKS[int(frac * 8)]
    return gauge

def fmt(label, pct):
    p = round(pct)
    return f'{DIM}{label}{R} {gradient(pct)}{spark_gauge(pct)}{R} {p}%'

model = data.get('model', {}).get('display_name', 'Claude')
parts = [model]

ctx = data.get('context_window', {}).get('used_percentage')
if ctx is not None:
    parts.append(fmt('ctx', ctx))

five = data.get('rate_limits', {}).get('five_hour', {}).get('used_percentage')
if five is not None:
    parts.append(fmt('5h', five))

# Show 5h rate limit reset time in JST if resets_at is present and usage > 0
five_resets_at = data.get('rate_limits', {}).get('five_hour', {}).get('resets_at')
if five is not None and five > 0 and five_resets_at is not None:
    JST = datetime.timezone(datetime.timedelta(hours=9))
    now_utc = datetime.datetime.now(datetime.timezone.utc)
    reset_dt = datetime.datetime.fromtimestamp(five_resets_at, tz=JST)
    reset_time_str = reset_dt.strftime('%H:%M')
    diff = reset_dt - now_utc.astimezone(JST)
    total_seconds = int(diff.total_seconds())
    if total_seconds > 0:
        hours, remainder = divmod(total_seconds, 3600)
        minutes = remainder // 60
        if hours > 0 and minutes > 0:
            remaining_str = f'あと {hours}h{minutes}m'
        elif hours > 0:
            remaining_str = f'あと {hours}h'
        else:
            remaining_str = f'あと {minutes}m'
        parts.append(f'{DIM}解放{R} {reset_time_str} {DIM}({remaining_str}){R}')

week = data.get('rate_limits', {}).get('seven_day', {}).get('used_percentage')
if week is not None:
    parts.append(fmt('7d', week))

print(f' {DIM}│{R} '.join(parts), end='')
