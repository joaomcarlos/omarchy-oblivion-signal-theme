# Replace script-output file polling with `send_udp` (Factorio 2.1)

Context for the agent doing this change. Today the pipeline is:

```
control.lua → helpers.write_file("oblivion-science.jsonl", line, append=true)
            → ~/.factorio/script-output/oblivion-science.jsonl
rail/ui/science.py → polls file size every 0.5 s → tails from a byte offset
```

Factorio 2.1 added a native UDP channel, so we can push each sample as a
datagram and delete the file entirely.

## The API

`helpers.send_udp(port, data, for_player?)`

- Sends one UDP datagram to **localhost only** at `port`. `data` is a
  LocalisedString — a JSON string from `helpers.table_to_json` is fine.
- **The game must be launched with `--enable-lua-udp <port>`** or the call
  silently does nothing. The flag's argument is the port the *game* listens on
  for inbound packets — we don't need inbound for telemetry, but the flag still
  requires a value (use `34199`; our listener port `34198` is the *destination*
  we pass to `send_udp`, unrelated).
- `for_player` scopes the send to one player's instance. Leave it unset for this
  mod (singleplayer rail). Note for the future: in multiplayer, an unset
  `for_player` means *every player's* instance sends → the listener would see
  duplicate samples.
- There is also `helpers.recv_udp` + the `on_udp_packet_received` event for
  inbound datagrams — not needed here, but it exists if the rail ever wants to
  push config into the game.

One call = one complete datagram = one complete JSON sample. No framing, no
newlines, no partial-line handling, no rotation — the exact reasons the file
code is complicated all disappear.

## Mod change (`factorio/oblivion-science-signal/control.lua`)

Everything in `sample()` up to building `line` stays. Then:

```lua
local TELEMETRY_PORT = 34198

-- before:
--   helpers.write_file(OUTPUT_FILE, line .. "\n", append)
-- after:
helpers.send_udp(TELEMETRY_PORT, line)
```

Delete: `OUTPUT_FILE`, `ROTATE_AFTER`, `storage.start_fresh`,
`storage.samples`, and the append/rotation block. `helpers.remove_path` exists
for cleaning up old installs' leftover file, but a stale
`oblivion-science.jsonl` in script-output is harmless — optional.

Update `info.json` description (no longer mentions script-output/JSONL).

## Listener change (`rail/ui/science.py`)

Replace the tail loop with a blocking UDP socket. The skeleton:

```python
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("127.0.0.1", 34198))
sock.settimeout(1.0)

while True:
    try:
        data, _ = sock.recvfrom(65535)
    except socket.timeout:
        pass
    else:
        try:
            sample = json.loads(data.decode("utf-8", "replace"))
        except ValueError:
            continue
        emit(sample)
        last_sample = time.time()
        stale_sent = False
        # ... existing icon-resolution block unchanged ...

    if last_sample and time.time() - last_sample > STALE_AFTER and not stale_sent:
        emit({"stale": True})
        stale_sent = True
```

What goes away: `PATH`, `INITIAL_TAIL`, the offset/`getsize`/seek/tell
machinery, the "file rewritten" rewind, the missing-file stale path, and the
partial-line `ValueError` guard can stay but will never fire (a datagram is
atomic). Keep: `emit`, the stale marker logic, `data_roots`/`icon_source`/
`cache_icon`/`resolve_icons` — the /proc probing for the game data dir is still
needed for icons.

## User-facing requirement

Factorio must start with the flag or the panel goes permanently stale:

```
--enable-lua-udp 34199 %command%
```

in the game's Steam launch options (Properties → Launch Options), or on the
command line for a non-Steam install. This is worth a line in the rail's
README/setup notes because a missing flag fails silently — same symptom as
"game not running".

## Caveats

- Datagrams are **not guaranteed** — loopback drops are rare at 1 Hz and a lost
  sample is replaced one second later; fine for telemetry, don't use UDP for
  anything that must not be lost.
- Max datagram ~64 KB; our sample is a few hundred bytes.
- No auth on the port — anything on localhost can send to the listener; keep
  the `json.loads` + schema tolerance (`sample.get(...)`) defensive.
- Inbound packets to the game (if ever added) become multiplayer input actions
  — keep any future inbound traffic small.
- There was a `recv_udp(0)` crash on headless 2.1.9; irrelevant here since we
  only send, and send doesn't need `for_player`.

Sources: https://lua-api.factorio.com/latest/classes/LuaHelpers.html
(`send_udp`/`recv_udp`), https://wiki.factorio.com/Command_line_parameters
(`--enable-lua-udp`). Working example mod using this API:
`lamp_led_display` on the mod portal.
