#!/usr/bin/env python3
"""Tail the science log written by the Oblivion Signal Factorio addon and
stream each sample to the rail, one JSON line per stdout write.

The addon (factorio/oblivion-science-signal) appends one line per second to
script-output/oblivion-science.jsonl. When the game is not running — or the
file has gone quiet — a {"stale": true} marker is emitted so the panel can
say so instead of drawing a flat line.
"""
import json
import os
import sys
import time

PATH = os.path.expanduser("~/.factorio/script-output/oblivion-science.jsonl")
STALE_AFTER = 5.0
POLL = 0.5
# On first read, skip most of an existing file so a long session does not
# replay thousands of samples at once; the rail only keeps a 2-minute window.
INITIAL_TAIL = 65536


def emit(payload):
    try:
        print(json.dumps(payload), flush=True)
    except BrokenPipeError:  # the rail went away; nothing left to feed
        sys.exit(0)


def main():
    offset = 0
    first = True
    last_sample = 0.0
    stale_sent = False

    while True:
        try:
            size = os.path.getsize(PATH)
        except OSError:
            if not stale_sent:
                emit({"stale": True})
                stale_sent = True
            time.sleep(1.0)
            continue

        if size < offset:  # the addon rewrote the file
            offset = 0
        if first and size > INITIAL_TAIL:
            offset = size - INITIAL_TAIL

        if size > offset:
            with open(PATH, "r", errors="replace") as handle:
                handle.seek(offset)
                for line in handle:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        sample = json.loads(line)
                    except ValueError:
                        continue  # partial line from a concurrent append
                    emit(sample)
                    last_sample = time.time()
                    stale_sent = False
                offset = handle.tell()
            first = False
            continue

        first = False
        if last_sample and time.time() - last_sample > STALE_AFTER and not stale_sent:
            emit({"stale": True})
            stale_sent = True
        time.sleep(POLL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
