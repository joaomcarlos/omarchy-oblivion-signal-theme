import QtQuick
import Quickshell
import Quickshell.Io

// Palette for the Oblivion Signal telemetry rail. Reads the active Omarchy
// theme's colors.toml out of the state dir so the rail follows theme swaps.
// The defaults below are the Oblivion Signal pal, so the rail renders
// correctly even when the file is unreadable.
QtObject {
  id: root

  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")
  readonly property string colorsPath: stateHome + "/omarchy/current/theme/colors.toml"

  property color bg: "#080D13"
  property color bgLight: "#0D141C"
  property color surface: "#1B2A3A"
  property color structural: "#2C4A61"
  property color mutedData: "#5F7F93"
  property color accent: "#6FA8CC"
  property color bright: "#A3CFE3"
  property color readout: "#B5D2E3"
  property color brightest: "#E2EFF8"
  property color coral: "#A6455C"
  property color coralBright: "#C4705C"
  property color caution: "#D8D9A8"
  property color ok: "#87AEA2"

  function load(raw) {
    var c = {}
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
      if (m) c[m[1]] = m[2]
    }
    if (c.dark_background) bg = c.dark_background
    if (c.background) bgLight = c.background
    if (c.lighter_background) surface = c.lighter_background
    if (c.muted) structural = c.muted
    if (c.dark_foreground) mutedData = c.dark_foreground
    if (c.accent) accent = c.accent
    if (c.bright_cyan) bright = c.bright_cyan
    else if (c.light_foreground) bright = c.light_foreground
    if (c.foreground) readout = c.foreground
    if (c.bright_foreground) brightest = c.bright_foreground
    if (c.red) coral = c.red
    if (c.orange) coralBright = c.orange
    else if (c.bright_red) coralBright = c.bright_red
    if (c.yellow) caution = c.yellow
    if (c.green) ok = c.green
  }

  property FileView colorsFile: FileView {
    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onLoaded: root.load(text())
    // `omarchy theme set` swaps the whole theme dir atomically; a poll timer
    // below covers the case where the watch doesn't survive the inode swap.
    onFileChanged: reload()
  }

  property Timer repoll: Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: root.colorsFile.reload()
  }
}
