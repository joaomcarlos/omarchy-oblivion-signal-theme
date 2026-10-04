#!/usr/bin/env python3
"""Emit the currently-running Devin and Codex sessions as one JSON line per
tick for the rail's AGENTS // LIVE module.

Devin: session_locks/<slug>.lock holds a live PID; sessions.db
message_nodes yields the newest assistant text segment (transcript as
fallback).

Codex: a live `codex resume <uuid>` process maps to
~/.codex/sessions/**/rollout-*-<uuid>.jsonl; the last agent_message /
task_complete payload yields the stream lines.
"""
import glob
import json
import os
import sqlite3
import time

HOME = os.path.expanduser("~")
LOCKS = HOME + "/.local/share/devin/cli/session_locks"
TRANSCRIPTS = HOME + "/.local/share/devin/cli/transcripts"
SESSIONS_DB = HOME + "/.local/share/devin/cli/sessions.db"
CODEX_SESSIONS = HOME + "/.codex/sessions"
MAX_AGENTS = 5
LAST_LINES = 6
MAX_IDLE = 3 * 86400
TICK = 1.5


def pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def devin_sessions():
    out = []
    for lf in glob.glob(LOCKS + "/*.lock"):
        try:
            pid = int(open(lf).read().strip())
        except (OSError, ValueError):
            continue
        if not pid_alive(pid):
            continue
        slug = os.path.basename(lf)[:-5]
        out.append((devin_active(slug) or os.path.getmtime(lf),
                    "devin", slug))
    return out


def devin_active(slug):
    """Newest message node timestamp — activity even mid-turn, before the
    transcript file catches up."""
    try:
        con = sqlite3.connect("file:" + SESSIONS_DB + "?mode=ro", uri=True)
        row = con.execute(
            "SELECT MAX(created_at) FROM message_nodes WHERE session_id=?",
            (slug,)).fetchone()
        con.close()
        return row[0] or 0 if row else 0
    except Exception:
        return 0


def codex_sessions():
    """Running `codex resume <uuid>` / bare `codex` TUI processes."""
    out = []
    for comm in glob.glob("/proc/[0-9]*/comm"):
        pid = int(comm.split("/")[2])
        try:
            if open(comm).read().strip() not in ("codex",):
                continue
            cmdline = open("/proc/%d/cmdline" % pid, "rb").read().decode(
                "utf-8", "replace").split("\0")
        except OSError:
            continue
        args = [a for a in cmdline[1:] if a]
        if not args or args[0] in ("app-server", "code-mode-host",
                                   "mcp-server"):
            continue
        uuid = ""
        if args[0] == "resume" and len(args) > 1:
            uuid = args[1]
        active = 0
        if uuid:
            rollout = codex_rollout(uuid)
            if rollout:
                try:
                    active = os.path.getmtime(rollout)
                except OSError:
                    pass
        if not active:
            try:
                active = os.path.getmtime("/proc/%d" % pid)
            except OSError:
                pass
        out.append((active, "codex", uuid or "new"))
    return out


def devin_prompt(slug):
    """The session's latest user prompt, collapsed to one line."""
    try:
        con = sqlite3.connect("file:" + SESSIONS_DB + "?mode=ro", uri=True)
        row = con.execute(
            "SELECT chat_message FROM message_nodes WHERE session_id=?"
            " AND json_extract(chat_message,'$.role')='user'"
            " AND json_extract(chat_message,'$.content') != ''"
            " ORDER BY node_id DESC LIMIT 1", (slug,)).fetchone()
        con.close()
        if row:
            return " ".join(
                (json.loads(row[0]).get("content") or "").split())[:120]
    except Exception:
        pass
    return ""


def devin_lines(slug):
    """Newest assistant message node for the session — finer-grained than
    the transcript's per-step writes, so intra-turn text shows sooner."""
    try:
        con = sqlite3.connect("file:" + SESSIONS_DB + "?mode=ro", uri=True)
        row = con.execute(
            "SELECT chat_message FROM message_nodes WHERE session_id=?"
            " AND json_extract(chat_message,'$.role')='assistant'"
            " AND json_extract(chat_message,'$.content') != ''"
            " ORDER BY node_id DESC LIMIT 1", (slug,)).fetchone()
        con.close()
        if row:
            lines = [l.strip() for l in
                     (json.loads(row[0]).get("content") or "")
                     .splitlines() if l.strip()]
            if lines:
                return lines[-LAST_LINES:]
    except Exception:
        pass
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


def codex_rollout(uuid):
    hits = glob.glob(CODEX_SESSIONS + "/*/*/*/rollout-*-%s.jsonl" % uuid)
    return hits[0] if hits else ""


def codex_prompt(path):
    """The session's latest user_message from the rollout tail."""
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            f.seek(max(0, size - 524288))
            tail = f.read().decode("utf-8", "replace")
    except OSError:
        return ""
    for line in reversed(tail.splitlines()):
        line = line.strip()
        if not line:
            continue
        try:
            payload = json.loads(line).get("payload", {})
        except (ValueError, AttributeError):
            continue
        if payload.get("type") == "user_message":
            text = " ".join((payload.get("message") or "").split())
            if text:
                return text[:120]
        item = payload.get("item") or {}
        if payload.get("type") == "item_completed" and \
                item.get("type") == "UserMessage":
            for chunk in item.get("content") or []:
                text = " ".join((chunk.get("text") or "").split())
                if text:
                    return text[:120]
    return ""


def codex_lines(path):
    """Last agent_message / task_complete text from the rollout tail."""
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            f.seek(max(0, size - 262144))
            tail = f.read().decode("utf-8", "replace")
    except OSError:
        return []
    for line in reversed(tail.splitlines()):
        line = line.strip()
        if not line:
            continue
        try:
            payload = json.loads(line).get("payload", {})
        except (ValueError, AttributeError):
            continue
        text = ""
        if payload.get("type") == "agent_message":
            text = payload.get("message", "")
        elif payload.get("type") == "task_complete":
            text = payload.get("last_agent_message", "")
        if text:
            lines = [l.strip() for l in text.splitlines() if l.strip()]
            return lines[-LAST_LINES:]
    return []


def codex_title(path, uuid):
    """First user message of the session as a readable tag."""
    try:
        with open(path) as f:
            for line in f:
                try:
                    payload = json.loads(line).get("payload", {})
                except ValueError:
                    continue
                if payload.get("type") == "user_message":
                    text = " ".join(payload.get("message", "").split())
                    if text:
                        return text[:18]
    except OSError:
        pass
    return uuid[:8]


while True:
    found = devin_sessions() + codex_sessions()
    now = time.time()
    found = [f for f in found if now - f[0] < MAX_IDLE]
    found.sort(reverse=True)
    agents = []
    for _, kind, ident in found[:MAX_AGENTS]:
        if kind == "devin":
            agents.append({"id": ident, "kind": kind,
                           "prompt": devin_prompt(ident),
                           "lines": devin_lines(ident)})
        else:
            path = codex_rollout(ident) if ident != "new" else ""
            agents.append({
                "id": codex_title(path, ident) if path else "codex",
                "kind": kind,
                "prompt": codex_prompt(path) if path else "",
                "lines": codex_lines(path) if path else []})
    print(json.dumps({"agents": agents}), flush=True)
    time.sleep(TICK)
