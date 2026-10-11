#!/usr/bin/env python3
"""Relay science telemetry from the Oblivion Signal Factorio addon to the
rail, one JSON line per stdout write.

The addon (factorio/oblivion-science-signal) sends each sample as a UDP
datagram to 127.0.0.1:34200 when the game is launched with --enable-lua-udp,
and this listener ACKs every datagram back to the game's port 34199 — the
mod only appends to script-output/oblivion-science.jsonl while no ACKs are
arriving, so the file is a live fallback, not a second copy. This listener
prefers UDP once a datagram has arrived — before that it tails the file, so
games launched without the flag keep working unchanged. When the game is
not running — or samples have gone quiet — a {"stale": true} marker is
emitted so the panel can say so instead of drawing a flat line.
"""
import glob
import json
import os
import socket
import subprocess
import sys
import time

LISTEN_PORT = 34200
GAME_PORT = 34199  # the game's --enable-lua-udp port; ACKs go back to it
PATH = os.path.expanduser("~/.factorio/script-output/oblivion-science.jsonl")
ICON_CACHE = os.path.expanduser("~/.cache/oblivion-signal/science-icons")
STALE_AFTER = 5.0
POLL = 0.25
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
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("127.0.0.1", LISTEN_PORT))
    sock.setblocking(False)

    offset = 0
    first = True
    udp_seen = False
    last_sample = 0.0
    stale_sent = False
    known_packs = set()

    def handle(sample):
        nonlocal last_sample, stale_sent
        if not isinstance(sample, dict):  # defensive: the port is open to localhost
            return
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

    while True:
        # Drain whatever UDP has for us. One datagram is proof the game was
        # launched with --enable-lua-udp, so it takes over the feed for good.
        while True:
            try:
                data, _ = sock.recvfrom(65535)
            except BlockingIOError:
                break
            try:
                sample = json.loads(data.decode("utf-8", "replace"))
            except ValueError:
                continue
            if isinstance(sample, dict):
                if not udp_seen:
                    emit({"udp": True})  # link went live
                    udp_seen = True
                # ACK back to the game's port — the mod gates its file
                # fallback on these arriving.
                sock.sendto(b"oblivion-ack", ("127.0.0.1", GAME_PORT))
                handle(sample)

        # Until UDP proves itself, fall back to tailing the file.
        if not udp_seen:
            try:
                size = os.path.getsize(PATH)
            except OSError:
                size = -1
            if size < 0:
                if not stale_sent:
                    emit({"stale": True})
                    stale_sent = True
            else:
                if size < offset:  # the addon rewrote the file
                    offset = 0
                if first and size > INITIAL_TAIL:
                    offset = size - INITIAL_TAIL
                if size > offset:
                    with open(PATH, "r", errors="replace") as handle_file:
                        handle_file.seek(offset)
                        for line in handle_file:
                            line = line.strip()
                            if not line:
                                continue
                            try:
                                handle(json.loads(line))
                            except ValueError:
                                continue  # partial line from a concurrent append
                        offset = handle_file.tell()
            first = False

        if udp_seen and last_sample and time.time() - last_sample > STALE_AFTER:
            udp_seen = False       # feed went quiet — report link down and
            emit({"udp": False})   # let the file tail take over again
        if last_sample and time.time() - last_sample > STALE_AFTER and not stale_sent:
            emit({"stale": True})
            stale_sent = True
        time.sleep(POLL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
