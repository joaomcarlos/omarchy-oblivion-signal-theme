#!/usr/bin/env python3
"""Emit the currently-running Devin sessions as one JSON line per tick for
the rail's AGENTS // LIVE module.

A session counts as running when its session_locks/<slug>.lock holds a live
PID. For each of the five most-recently-active sessions we emit the last
lines of the latest agent message in transcripts/<slug>.json.
"""
import glob
import json
import os
import time

HOME = os.path.expanduser("~")
LOCKS = HOME + "/.local/share/devin/cli/session_locks"
TRANSCRIPTS = HOME + "/.local/share/devin/cli/transcripts"
MAX_AGENTS = 5
LAST_LINES = 2
TICK = 2.5


def pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def running_slugs():
    out = []
    for lf in glob.glob(LOCKS + "/*.lock"):
        try:
            pid = int(open(lf).read().strip())
        except (OSError, ValueError):
            continue
        if not pid_alive(pid):
            continue
        slug = os.path.basename(lf)[:-5]
        transcript = TRANSCRIPTS + "/" + slug + ".json"
        try:
            active = os.path.getmtime(transcript)
        except OSError:
            active = os.path.getmtime(lf)
        out.append((active, slug))
    out.sort(reverse=True)
    return [slug for _, slug in out[:MAX_AGENTS]]


def last_agent_lines(slug):
    try:
        with open(TRANSCRIPTS + "/" + slug + ".json") as f:
            steps = json.load(f).get("steps") or []
    except Exception:
        return []
    for step in reversed(steps):
        if step.get("source") == "agent" and step.get("message"):
            lines = [l.strip() for l in step["message"].splitlines()
                     if l.strip()]
            return lines[-LAST_LINES:]
    return []


while True:
    agents = [{"id": s, "lines": last_agent_lines(s)}
              for s in running_slugs()]
    print(json.dumps({"agents": agents}), flush=True)
    time.sleep(TICK)
