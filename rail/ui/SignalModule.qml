import QtQuick
import Quickshell
import Quickshell.Io

// SIGNAL // CH 03 — real FFT from cava (PipeWire, 48 bars): blocky marks
// above and below a baseline, one coral anomaly column on channel 07, and a
// mechanical scan sweep. Falls back to a CPU-biased random walk without cava.
RailModule {
  id: root
  label: "SIGNAL // CH 03"
  state: "ACQUIRING"
  stateDot: pal.accent

  readonly property int columns: 48
  readonly property int anomalyColumn: 7
  // heights[0..13] bars above the baseline, heights[14..27] below
  property var heights: []
  property bool flickerOn: true
  // true while cava emits frames — the random walk only runs as fallback
  property bool live: false

  function tick() {
    var h = heights.slice()
    var bias = vitals.cpu / 100
    for (var i = 0; i < h.length; i++) {
      // Mean-reverting walk toward a per-column target that follows CPU
      // load — jitter stays alive, bars sit mid-band instead of pinning
      // at the cap.
      var shape = 0.35 + 0.65 * (((i * 7) % 13) / 12)
      var target = 3 + bias * 18 * shape
      h[i] = Math.max(3, Math.min(26, Math.round(
        h[i] + (target - h[i]) * 0.18 + (Math.random() - 0.5) * 7)))
    }
    heights = h
  }

  Component.onCompleted: {
    var h = []
    for (var i = 0; i < columns * 2; i++) h.push(4 + Math.round(Math.random() * 12))
    heights = h
  }

  // "48kHz · 16-bit" / "4096-pt FFT"
  Item {
    width: parent.width
    height: 12

    Text {
      anchors.left: parent.left
      text: "48KHZ · 16-BIT"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.3
    }
    Text {
      anchors.right: parent.right
      text: "4096-PT FFT"
      color: pal.mutedData
      font.family: "OCRA"
      font.pixelSize: 9
    }
  }

  Item {
    id: graph
    width: parent.width
    height: 64

    Process {
      id: cava
      running: root.visible
      command: ["cava", "-p",
        Qt.resolvedUrl("../cava.conf").toString().replace("file://", "")]
      stdout: SplitParser {
        onRead: function(line) {
          var parts = line.split(";")
          var h = []
          for (var i = 0; i < root.columns; i++) {
            var v = parseInt(parts[i] || "0")
            // cava ascii raw tops out around 1000 with autosens
            h.push(Math.max(2, Math.min(26, Math.round(v / 40))))
          }
          for (i = 0; i < root.columns; i++)
            h.push(Math.max(1, Math.round(h[i] * 0.55)))
          root.heights = h
          root.live = true
        }
      }
      onExited: root.live = false
    }

    Timer {
      interval: 220
      repeat: true
      running: root.visible && !root.live
      onTriggered: root.tick()
    }

    Timer {
      interval: 400
      repeat: true
      running: root.visible
      onTriggered: root.flickerOn = !root.flickerOn
    }

    // baseline
    Rectangle {
      anchors {
        left: parent.left
        right: parent.right
        verticalCenter: parent.verticalCenter
      }
      height: 1
      color: Qt.alpha(pal.structural, 0.5)
    }

    // sparse reference dots + phase ticks along the baseline
    Repeater {
      model: 3
      Item {
        x: graph.width * (index + 1) / 8

        Rectangle {
          x: -1
          y: graph.height / 2 - 1
          width: 2
          height: 2
          color: pal.bright
        }
        Rectangle {
          x: -0.5
          y: graph.height / 2
          width: 1
          height: 4
          color: Qt.alpha(pal.structural, 0.8)
        }
      }
    }

    Row {
      anchors.fill: parent

      Repeater {
        model: root.columns

        Item {
          required property int index
          readonly property bool anomaly: index === root.anomalyColumn
          readonly property real up: root.heights.length > index ? root.heights[index] : 8
          readonly property real down: root.heights.length > index + root.columns ? root.heights[index + root.columns] : 6

          width: graph.width / root.columns
          height: graph.height

          Rectangle {
            anchors {
              horizontalCenter: parent.horizontalCenter
              bottom: parent.verticalCenter
            }
            width: 4
            height: parent.up
            color: parent.anomaly ? pal.coral : pal.accent
            opacity: parent.anomaly ? (root.flickerOn ? 0.8 : 0.35) : 0.7
          }
          Rectangle {
            anchors {
              horizontalCenter: parent.horizontalCenter
              top: parent.verticalCenter
            }
            width: 4
            height: parent.down
            color: parent.anomaly ? pal.coral : pal.accent
            opacity: parent.anomaly ? (root.flickerOn ? 0.6 : 0.25) : 0.5
          }
        }
      }
    }

    ScanBeam {
      anchors.fill: parent
      interval: 375
      pal: root.pal
    }
  }

  // "CH 07" + warn icon
  Item {
    width: parent.width
    height: 14

    Text {
      anchors {
        left: parent.left
        verticalCenter: parent.verticalCenter
      }
      text: "CH 07"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.3
    }

    // Warning icon — exclamation in a square frame, the film's evolved skull.
    Rectangle {
      anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
      }
      width: 12
      height: 12
      color: "transparent"
      border.width: 1
      border.color: pal.coral
      opacity: root.flickerOn ? 1 : 0.5

      Text {
        anchors.centerIn: parent
        text: "!"
        color: pal.coral
        font.family: "Blender Trial"
        font.pixelSize: 9
        font.bold: true
      }
    }
  }
}
