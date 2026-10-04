import QtQuick
import Quickshell
import Quickshell.Io

// Live system vitals for the rail, fed one JSON line per tick by poll.sh.
// The FFT trace and radar grid are decorative; everything here is real.
QtObject {
  id: root

  property int cpu: 0
  property int temp: -1
  property int gpu: -1    // -1 = no NVIDIA telemetry
  property int gtemp: -1
  property int vram: -1
  property int mem: 0
  property int rx: 0       // bytes/s inbound
  property int tx: 0       // bytes/s outbound
  property string pwr: "AC" // battery percent, "+NN" while charging, "AC" when none
  property int disk: 0
  property string up: ""
  property bool degraded: false

  function ingest(line) {
    var d
    try {
      d = JSON.parse(line)
    } catch (e) {
      return
    }
    cpu = d.cpu | 0
    temp = d.temp | 0
    if (d.gpu !== undefined) gpu = d.gpu | 0
    if (d.gtemp !== undefined) gtemp = d.gtemp | 0
    if (d.vram !== undefined) vram = d.vram | 0
    mem = d.mem | 0
    rx = d.rx | 0
    tx = d.tx | 0
    if (d.pwr !== undefined) pwr = String(d.pwr)
    disk = d.disk | 0
    if (d.up !== undefined) up = String(d.up)
    degraded = cpu > 90 || mem > 90 || disk > 90 || (temp >= 0 && temp > 85)
  }

  readonly property string pollPath: Qt.resolvedUrl("poll.sh").toString().replace(/^file:\/\//, "")

  property Process poller: Process {
    command: ["bash", root.pollPath]
    running: true
    stdout: SplitParser {
      onRead: function(data) { root.ingest(data) }
    }
    onExited: restartTimer.start()
  }

  property Timer restartTimer: Timer {
    interval: 1500
    onTriggered: root.poller.running = true
  }
}
