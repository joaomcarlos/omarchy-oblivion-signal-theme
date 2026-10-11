#!/usr/bin/env bash
# Single-instance launcher for the rail. Both the theme hook's start_rail()
# and the autostart.lua exec_on_start line call this, so a Hyprland reload
# while the rail is already running cannot stack a second instance (a dead
# duplicate's science.py fails its port bind and its panel freezes over the
# live one).
pgrep -f "quickshell.*oblivion-signal/rail" >/dev/null && exit 0
exec quickshell -p "$HOME/.config/omarchy/themes/oblivion-signal/rail"
