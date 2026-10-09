#!/usr/bin/env python3
"""Tail the science log written by the Oblivion Signal Factorio addon and
stream each sample to the rail, one JSON line per stdout write.

The addon (factorio/oblivion-science-signal) appends one line per second to
script-output/oblivion-science.jsonl. When the game is not running — or the
file has gone quiet — a {"stale": true} marker is emitted so the panel can
say so instead of drawing a flat line.
"""
import glob
import json
import os
import subprocess
import sys
import time

PATH = os.path.expanduser("~/.factorio/script-output/oblivion-science.jsonl")
ICON_CACHE = os.path.expanduser("~/.cache/oblivion-signal/science-icons")
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


def data_roots():
    """Locate the game's data directory, preferring the running install."""
    roots = []
    for cmd in glob.glob("/proc/[0-9]*/cmdline"):
        try:
            parts = open(cmd, "rb").read().decode("utf-8", "replace").split("\0")
        except OSError:
            continue
        for part in parts:
            if part.endswith("/factorio") or part.endswith("/factorio-bin"):
                # <root>/bin/x64/factorio -> <root>/data
                install = os.path.dirname(os.path.dirname(os.path.dirname(part)))
                roots.append(os.path.join(install, "data"))
    roots += [
        os.path.expanduser("~/.local/share/Steam/steamapps/common/Factorio/data"),
        os.path.expanduser("~/factorio/data"),
        "/opt/factorio/data",
    ]
    seen, out = set(), []
    for root in roots:
        if root not in seen and os.path.isdir(root):
            seen.add(root)
            out.append(root)
    return out


def icon_source(name, roots):
    for root in roots:
        for mod in ("base", "space-age", "quality", "elevated-rails"):
            path = os.path.join(root, mod, "graphics", "icons", name + ".png")
            if os.path.exists(path):
                return path
    hits = glob.glob(os.path.expanduser(
        "~/.factorio/mods/*/graphics/icons/%s.png" % name))
    return hits[0] if hits else ""


def cache_icon(name, source):
    """Crop the sheet's first 64x64 frame to a small cached PNG.

    The icons are Wube's game art, so they are never vendored into the theme
    repo — they are cropped out of the local install into a cache dir.
    """
    out = os.path.join(ICON_CACHE, name + ".png")
    try:
        if os.path.getmtime(out) >= os.path.getmtime(source):
            return out
    except OSError:
        pass
    try:
        os.makedirs(ICON_CACHE, exist_ok=True)
        subprocess.run(["magick", source, "-crop", "64x64+0+0", "+repage",
                        "-resize", "32x32", out], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (OSError, subprocess.CalledProcessError):
        return ""
    return out


def resolve_icons(names):
    roots = data_roots()
    icons = {}
    for name in names:
        source = icon_source(name, roots)
        if source:
            cached = cache_icon(name, source)
            if cached:
                icons[name] = cached
    return icons


def main():
    offset = 0
    first = True
    last_sample = 0.0
    stale_sent = False
    known_packs = set()

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
                    # crop the game's icons for any pack we have not seen yet
                    fresh = [n for n in (sample.get("spm") or {})
                             if n not in known_packs]
                    if fresh:
                        known_packs.update(fresh)
                        icons = resolve_icons(sorted(known_packs))
                        if icons:
                            emit({"icons": icons})
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
