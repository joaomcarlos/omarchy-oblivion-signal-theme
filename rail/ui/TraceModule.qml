import QtQuick
import QtQuick.Shapes

// TRACE // LOAD — a rolling 2-minute instrument trace: CPU and MEM as
// overlaid readout lines (shared 0–100 axis), NET throughput as stepped
// baseline bars on a decaying scale. Same visual idiom as the survey
// reticle: hairline grid, edge labels, coral anomaly marker, scan sweep.
RailModule {
  id: root
  label: "TRACE // LOAD"
  state: "C" + vitals.cpu + " · M" + vitals.mem

  readonly property int samples: 64
  property var cpuHist: []
  property var memHist: []
  property var netHist: []
  property real netMax: 65536

  function pts(hist, scale, w, h) {
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

  function push() {
    var rate = vitals.rx + vitals.tx
    cpuHist = cpuHist.concat([vitals.cpu]).slice(-samples)
    memHist = memHist.concat([vitals.mem]).slice(-samples)
    netHist = netHist.concat([rate]).slice(-samples)
    netMax = Math.max(65536, netMax * 0.97, rate)
    cpuPts = pts(cpuHist, 100, graph.width, graph.height)
    memPts = pts(memHist, 100, graph.width, graph.height)
  }
  property var cpuPts: []
  property var memPts: []

  // legend row — same split as the 48KHZ / 4096-PT line
  Item {
    width: parent.width
    height: 12

    Text {
      anchors.left: parent.left
      text: "CPU · MEM · NET"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.3
    }
    Text {
      anchors.right: parent.right
      text: (vitals.rx + vitals.tx < 1048576
             ? Math.round((vitals.rx + vitals.tx) / 1024) + "KB/S"
             : ((vitals.rx + vitals.tx) / 1048576).toFixed(1) + "MB/S")
      color: pal.mutedData
      font.family: "OCRA"
      font.pixelSize: 9
    }
  }

  Item {
    id: graph
    width: parent.width
    height: width * 0.5

    Timer {
      interval: 2000
      repeat: true
      running: root.visible
      triggeredOnStart: true
      onTriggered: root.push()
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

    // NET throughput — stepped baseline bars on a self-decaying scale
    Repeater {
      model: root.netHist.length
      Rectangle {
        x: graph.width * (root.samples - root.netHist.length + index) / (root.samples - 1)
        anchors.bottom: parent.bottom
        width: 2
        height: Math.min(1, root.netHist[index] / root.netMax) * graph.height * 0.45
        color: Qt.alpha(pal.mutedData, 0.55)
      }
    }

    // MEM — translucent filled trace under the line
    Shape {
      anchors.fill: parent
      ShapePath {
        strokeColor: Qt.alpha(pal.bright, 0.7)
        strokeWidth: 1
        fillColor: Qt.alpha(pal.bright, 0.08)
        PathMove { x: 0; y: graph.height }
        PathPolyline { path: root.memPts }
        PathLine { x: graph.width; y: graph.height }
      }
    }

    // CPU — the primary readout line
    Shape {
      anchors.fill: parent
      ShapePath {
        strokeColor: pal.accent
        strokeWidth: 1
        fillColor: "transparent"
        PathPolyline { path: root.cpuPts }
      }
    }

    // coral anomaly marker — outlined square with an X, on DEGRADED
    Item {
      x: graph.width * 0.70
      y: graph.height * 0.12
      width: 10
      height: 10
      opacity: vitals.degraded ? 0.9 : 0.15

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
      text: "100"
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
