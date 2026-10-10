import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

// SCIENCE // RESEARCH — science-per-second off the Factorio addon's log:
// a rolling 10-minute trace of packs consumed per second, the technology
// under research and its progress. Same idiom as the load trace: hairline
// grid, edge labels, coral anomaly marker, scan sweep.
RailModule {
  id: root
  label: "SCIENCE // RESEARCH"
  state: stale ? "NO SIGNAL" : (tech !== "" ? tech.toUpperCase() : "IDLE")
  stateDot: stale ? pal.coral : (tech !== "" ? pal.accent : pal.mutedData)
  alert: stale

  readonly property int samples: 600 // 1 Hz samples: a 10-minute window
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
  // one column per pack type, in the game's own progression order
  property var packNames: []
  property real packMax: 1
  property real maxPackRate: 0
  // pack name -> cropped icon path, resolved by the tailer from the local
  // Factorio install (the game art is never vendored into the repo)
  property var icons: ({})

  function ingest(line) {
    var d
    try {
      d = JSON.parse(line)
    } catch (e) {
      return
    }
    if (d.icons) {
      icons = d.icons
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
    if (packNames.length === 0)
      packNames = Object.keys(packs).sort(function(a, b) {
        var ra = packOrder.indexOf(a)
        var rb = packOrder.indexOf(b)
        if (ra < 0) ra = packOrder.length
        if (rb < 0) rb = packOrder.length
        return ra !== rb ? ra - rb : (a < b ? -1 : 1)
      })
    var peak = 0
    for (var i = 0; i < packNames.length; i++)
      peak = Math.max(peak, packs[packNames[i]] || 0)
    maxPackRate = peak
    packMax = Math.max(1, packMax * 0.98, peak)
    spmHist = spmHist.concat([total]).slice(-samples)
    // scale to the tallest sample in the window, not a decaying peak, so a
    // point's height is fixed once drawn — the trace only re-scales when a
    // new maximum enters or the old one scrolls off the left edge
    var win = 60
    for (var j = 0; j < spmHist.length; j++)
      win = Math.max(win, spmHist[j])
    spmMax = win
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

  // Each pack's mark, in that pack's colour. The base game marks are the
  // letter of the colour the pack is known by (R red, G green, G grey, B
  // blue, P purple, Y yellow, W white). Space Age packs have no colour name
  // in the wiki, so theirs is the letter of the science itself — M for
  // metallurgic, and so on. Hues are averaged from the game's own icons.
  readonly property var packMarks: ({
    "automation-science-pack": { letter: "R", color: "#F47C7C" },       // red
    "logistic-science-pack": { letter: "G", color: "#85F589" },         // green
    "military-science-pack": { letter: "G", color: "#C0C2D1" },         // grey
    "chemical-science-pack": { letter: "B", color: "#7FE1FF" },         // blue
    "production-science-pack": { letter: "P", color: "#CF72FC" },       // purple
    "utility-science-pack": { letter: "Y", color: "#FFDE85" },          // yellow
    "space-science-pack": { letter: "W", color: "#FFFDFD" },            // white
    "metallurgic-science-pack": { letter: "M", color: "#FF9028" },      // orange
    "electromagnetic-science-pack": { letter: "E", color: "#FF4BAB" },  // magenta
    "agricultural-science-pack": { letter: "A", color: "#C0D128" },     // lime
    "cryogenic-science-pack": { letter: "C", color: "#6070F0" },        // indigo
    "promethium-science-pack": { letter: "P", color: "#ABB0CC" },       // slate
  })

  // The order the game introduces them: the base-game tree, then the Space
  // Age packs in the wiki's listing order. Modded packs, which have no place
  // in that progression, sort alphabetically after the rest.
  readonly property var packOrder: [
    "automation-science-pack", "logistic-science-pack",
    "military-science-pack", "chemical-science-pack",
    "production-science-pack", "utility-science-pack",
    "space-science-pack", "metallurgic-science-pack",
    "electromagnetic-science-pack", "agricultural-science-pack",
    "cryogenic-science-pack", "promethium-science-pack"
  ]

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
                            : "SPS // PACKS CONSUMED")
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.3
      elide: Text.ElideRight
    }
    Text {
      anchors.right: parent.right
      // the log carries per-minute rates; the game displays per-second
      text: stale ? "--" : spm(total / 60) + "/s"
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

    // the pack columns, grouped tight in their own bordered box, anchored
    // to the graph's left edge
    Item {
      id: packBox
      anchors.left: parent.left
      anchors.leftMargin: 4 // lines up with the "0" axis mark
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 13 // clears the time-axis labels
      width: root.packNames.length * 14 + 2
      height: 68

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
          readonly property var mark: root.packMarks[modelData] || null
          readonly property string icon: root.icons[modelData] || ""

          x: 8 + index * 14
          width: 4
          height: packBox.height

          // thin mark per pack, like the signal bars
          Rectangle {
            id: bar
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 21
            width: 4
            height: parent.rate <= 0 ? 1
                  : Math.max(2, parent.rate / root.packMax * 32)
            color: parent.rate <= 0 ? Qt.alpha(pal.structural, 0.5)
                 : (parent.leader ? pal.bright : pal.accent)
            opacity: parent.rate <= 0 ? 1 : (parent.leader ? 0.85 : 0.7)
          }

          // the pack's own icon from the local install, centred under the bar
          Image {
            visible: parent.icon !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            source: parent.icon !== "" ? "file://" + parent.icon : ""
            sourceSize.width: 13
            sourceSize.height: 13
            width: 13
            height: 13
            smooth: true
            opacity: parent.leader ? 1 : 0.85
          }

          // fallback when the install has no icon for this pack
          Text {
            visible: parent.icon === ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            text: parent.mark ? parent.mark.letter
                              : modelData.replace(/-science-pack$/, "")
                                         .charAt(0).toUpperCase()
            color: parent.mark ? parent.mark.color : pal.mutedData
            opacity: parent.leader ? 1 : 0.85
            font.family: "Blender Trial"
            font.pixelSize: 7
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
      text: root.spm(root.spmMax / 60)
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
      text: "-10M"
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
