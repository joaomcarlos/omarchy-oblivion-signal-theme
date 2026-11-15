#!/usr/bin/env bash
# Single-instance launcher for the rail. The theme hook's start_rail(), the
# autostart.lua exec_on_start line, and the oblivion-rail systemd unit all
# call this, so a Hyprland reload while the rail is already running cannot
# stack a second instance (a dead duplicate's science.py fails its port bind
# and its panel freezes over the live one).
rail_pattern="quickshell.*oblivion-signal/rail"
if pgrep -f "$rail_pattern" >/dev/null; then
  # Outside systemd nothing more is needed. Inside the oblivion-rail unit
  # (INVOCATION_ID is set) a foreign launcher won the race: watch the live
  # instance and take over when it dies so the panel ends up supervised.
  [[ -n ${INVOCATION_ID:-} ]] || exit 0
  while pgrep -f "$rail_pattern" >/dev/null; do sleep 3; done
  [[ $(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null) == "oblivion-signal" ]] || exit 0
fi
exec quickshell -p "$HOME/.config/omarchy/themes/oblivion-signal/rail"
