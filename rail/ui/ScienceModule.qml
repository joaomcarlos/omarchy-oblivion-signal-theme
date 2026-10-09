import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

// SCIENCE // RESEARCH — science-per-minute off the Factorio addon's log:
// a rolling 2-minute trace of packs consumed per minute, the technology
// under research and its progress. Same idiom as the load trace: hairline
// grid, edge labels, coral anomaly marker, scan sweep.
RailModule {
  id: root
  label: "SCIENCE // RESEARCH"
  state: stale ? "NO SIGNAL" : (tech !== "" ? tech.toUpperCase() : "IDLE")
  stateDot: stale ? pal.coral : (tech !== "" ? pal.accent : pal.mutedData)
  alert: stale

  readonly property int samples: 120 // 1 Hz samples: a 2-minute window
  property bool stale: true
  property string tech: ""
  property string queue: ""
  property real prog: 0
  property real total: 0
  property var packs: ({})
  property var spmHist: []
  property real spmMax: 60
  property var spmPts: []
  property var spmFill: []
  // one column per pack type, in the log's stable (alphabetical) order
  property var packNames: []
  property real packMax: 1
  property real maxPackRate: 0

  function ingest(line) {
    var d
    try {
      d = JSON.parse(line)
    } catch (e) {
      return
    }
    if (d.stale) {
      stale = true
      return
    }
    stale = false
    tech = d.tech || ""
    queue = d.queue || ""
    prog = d.prog || 0
    total = d.total || 0
    packs = d.spm || ({})
    if (packNames.length === 0) packNames = Object.keys(packs)
    var peak = 0
    for (var i = 0; i < packNames.length; i++)
      peak = Math.max(peak, packs[packNames[i]] || 0)
    maxPackRate = peak
    packMax = Math.max(1, packMax * 0.98, peak)
    spmHist = spmHist.concat([total]).slice(-samples)
    spmMax = Math.max(60, spmMax * 0.98, total)
    spmPts = points(spmHist, spmMax, graph.width, graph.height)
    // close the area under the trace explicitly, so a partly-filled window
    // does not draw a diagonal edge back to the origin
    spmFill = spmPts.concat([
      Qt.point(graph.width, graph.height),
      Qt.point(spmPts.length ? spmPts[0].x : 0, graph.height)])
  }

  function points(hist, scale, w, h) {
    var out = []
    var n = Math.min(hist.length, samples)
    var off = hist.length - n
    for (var i = 0; i < n; i++) {
      out.push(Qt.point(
        w * (samples - n + i) / (samples - 1),
        h - Math.min(1, hist[off + i] / scale) * h))
    }
    return out
  }

  // big factories run six figures of packs per minute — keep it compact
  function spm(value) {
    if (value >= 1e6) return (value / 1e6).toFixed(2) + "m"
    if (value >= 1e3) return (value / 1e3).toFixed(1) + "k"
    return value.toFixed(1)
  }

  // legend row — research name left, packs/min right
  Item {
    width: parent.width
    height: 12

    Text {
      anchors.left: parent.left
      width: parent.width * 0.62
      text: stale ? "AWAITING FACTORIO"
            : (queue !== "" ? "NEXT · " + queue.toUpperCase()
                            : "SPM // PACKS CONSUMED")
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.3
      elide: Text.ElideRight
    }
    Text {
      anchors.right: parent.right
      text: stale ? "--" : spm(total) + " spm"
      color: pal.mutedData
      font.family: "OCRA"
      font.pixelSize: 9
    }
  }

  // research progress — a hairline bar, filled to prog%
  Item {
    width: parent.width
    height: 9

    Text {
      id: progLabel
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: stale ? "--" : prog.toFixed(1) + "%"
      color: pal.readout
      font.family: "OCRA"
      font.pixelSize: 8
    }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: progLabel.x - 6
      height: 3
      color: Qt.alpha(pal.structural, 0.4)
    }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: (progLabel.x - 6) * Math.max(0, Math.min(100, prog)) / 100
      height: 3
      color: pal.accent
    }
  }

  Item {
    id: graph
    width: parent.width
    height: width * 0.5

    Process {
      running: root.visible
      command: ["python3",
        Qt.resolvedUrl("science.py").toString().replace("file://", "")]
      stdout: SplitParser {
        onRead: function(line) {
          root.ingest(line)
        }
      }
    }

    // hairline grid — 5 horizontal + 5 vertical lines
    Repeater {
      model: 5
      Rectangle {
        x: 0
        y: graph.height * (index + 1) / 6
        width: graph.width
        height: 1
        color: Qt.alpha(pal.structural, 0.3)
      }
    }
    Repeater {
      model: 5
      Rectangle {
        x: graph.width * (index + 1) / 6
        y: 0
        width: 1
        height: graph.height
        color: Qt.alpha(pal.structural, 0.3)
      }
    }

    // the pack columns, grouped tight in their own bordered box: 8px pitch
    // keeps the vertical names side by side without overlapping
    Item {
      id: packBox
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 13 // clears the time-axis labels
      width: root.packNames.length * 10 + 2
      height: 106

      Rectangle {
        anchors.fill: parent
        color: Qt.alpha(pal.bg, 0.45)
        border.width: 1
        border.color: Qt.alpha(pal.structural, 0.55)
      }

      Repeater {
        model: root.packNames

        Item {
          required property int index
          required property string modelData
          readonly property real rate: root.packs[modelData] || 0
          readonly property bool leader: rate >= root.maxPackRate && rate > 0

          x: 6 + index * 10
          width: 4
          height: packBox.height

          // thin mark per pack, like the signal bars
          Rectangle {
            id: bar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: 4
            height: parent.rate <= 0 ? 1
                  : Math.max(2, parent.rate / root.packMax * 32)
            color: parent.rate <= 0 ? Qt.alpha(pal.structural, 0.5)
                 : (parent.leader ? pal.bright : pal.accent)
            opacity: parent.rate <= 0 ? 1 : (parent.leader ? 0.85 : 0.7)
          }

          // pack name in its own band above the bars, running upward from
          // the bar's left edge
          Text {
            x: 1
            y: 38
            width: 62
            height: 8
            rotation: -90
            transformOrigin: Item.BottomLeft
            text: modelData.replace(/-science-pack$/, "").toUpperCase()
            color: parent.leader
                   ? Qt.alpha(pal.readout, 0.95) // brighter on the leader
                   : Qt.alpha(pal.mutedData, 0.9)
            font.family: "Blender Trial"
            font.pixelSize: 7
            font.letterSpacing: 0.6
            elide: Text.ElideRight
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }

    // science per minute — filled area under the line
    Shape {
      anchors.fill: parent
      ShapePath {
        strokeColor: "transparent"
        fillColor: Qt.alpha(pal.accent, 0.10)
        PathPolyline { path: root.spmFill }
      }
    }

    // the readout line itself
    Shape {
      anchors.fill: parent
      ShapePath {
        strokeColor: pal.accent
        strokeWidth: 1
        fillColor: "transparent"
        PathPolyline { path: root.spmPts }
      }
    }

    // coral anomaly marker — research stalled or the game has gone quiet
    Item {
      x: graph.width * 0.70
      y: graph.height * 0.12
      width: 10
      height: 10
      opacity: (root.stale || (root.tech !== "" && root.total === 0)) ? 0.9 : 0.15

      Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: pal.coral
      }
      Rectangle {
        anchors.centerIn: parent
        width: 12
        height: 1
        rotation: 45
        color: Qt.alpha(pal.coral, 0.5)
      }
      Rectangle {
        anchors.centerIn: parent
        width: 12
        height: 1
        rotation: -45
        color: Qt.alpha(pal.coral, 0.5)
      }
    }

    // edge labels — the trace's cardinal marks
    Text {
      anchors { top: parent.top; topMargin: 3; left: parent.left; leftMargin: 4 }
      text: root.spm(root.spmMax)
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 8
    }
    Text {
      anchors { bottom: parent.bottom; bottomMargin: 3; left: parent.left; leftMargin: 4 }
      text: "0"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 8
    }
    Text {
      anchors { bottom: parent.bottom; bottomMargin: 3; horizontalCenter: parent.horizontalCenter }
      text: "-2M"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 8
    }
    Text {
      anchors { bottom: parent.bottom; bottomMargin: 3; right: parent.right; rightMargin: 4 }
      text: "NOW"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 8
    }

    ScanBeam {
      anchors.fill: parent
      interval: 500
      pal: root.pal
    }
  }
}
