#!/usr/bin/env python3
# Feeds the rail's PROCESS module one JSON line per tick: the top 5 apps by
# current CPU%, aggregated by comm name so multi-process apps collapse into a
# single square. CPU% is a delta measured across the sleep window against
# /proc/stat, scaled like top (100% = one saturated core).
import json
import os
import time

NCPU = os.cpu_count() or 1
PAGE_KB = os.sysconf("SC_PAGESIZE") // 1024
INTERVAL = 2.0
TOP_N = 5


def total_jiffies():
    with open("/proc/stat") as f:
        return sum(int(x) for x in f.readline().split()[1:])


def mem_total_kb():
    with open("/proc/meminfo") as f:
        for line in f:
            if line.startswith("MemTotal:"):
                return int(line.split()[1])
    return 1


def snapshot():
    # -> {pid: (name, cpu_jiffies, rss_kb)} for userspace processes only;
    # kernel threads have an empty cmdline and are skipped.
    out = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                if not f.read(1):
                    continue
            with open(f"/proc/{pid}/stat") as f:
                s = f.read()
            rparen = s.rfind(")")
            name = s[s.find("(") + 1:rparen]
            fields = s[rparen + 2:].split()
            jiffies = int(fields[11]) + int(fields[12])  # utime + stime
            with open(f"/proc/{pid}/statm") as f:
                rss = int(f.read().split()[1]) * PAGE_KB
            out[int(pid)] = (name, jiffies, rss)
        except (FileNotFoundError, ProcessLookupError, PermissionError,
                IndexError, ValueError):
            continue
    return out


def main():
    mem_total = mem_total_kb()
    prev = snapshot()
    t_prev = total_jiffies()
    while True:
        time.sleep(INTERVAL)
        cur = snapshot()
        t_cur = total_jiffies()
        span = max(t_cur - t_prev, 1)

        agg = {}
        for pid, (name, j_cur, rss) in cur.items():
            j_prev = prev.get(pid, (name, j_cur, 0))[1]
            a = agg.setdefault(name, {"cpu": 0.0, "rss": 0, "n": 0})
            a["cpu"] += 100.0 * NCPU * (j_cur - j_prev) / span
            a["rss"] += rss
            a["n"] += 1

        rows = [
            {
                "name": name,
                "cpu": round(a["cpu"], 1),
                "mem": round(100.0 * a["rss"] / mem_total, 1),
                "mb": a["rss"] // 1024,
                "n": a["n"],
            }
            for name, a in agg.items()
            if a["cpu"] >= 0.3
        ]
        rows.sort(key=lambda r: r["cpu"], reverse=True)
        print(json.dumps({"procs": rows[:TOP_N]}), flush=True)

        prev = cur
        t_prev = t_cur


if __name__ == "__main__":
    main()
