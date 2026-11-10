import QtQuick
import Quickshell
import Quickshell.Io

// PROCESS // TOP LOAD — the five heaviest apps by current CPU%, one square
// each. procs.py samples /proc twice per tick, collapses multi-process apps
// into a single comm entry, and emits one JSON line.
// Cards keep their square layout. The shell reserves their height before
// assigning the remaining space to agent summaries.
RailModule {
  id: root
  label: "PROCESS // TOP LOAD"
  state: procs.length > 0 ? "PEAK " + procs[0].cpu.toFixed(0) + "%" : "IDLE"
  stateDot: procs.length > 0 ? pal.accent : pal.mutedData

  property var procs: []

  readonly property int columns: Math.max(1, Math.floor((width + 2) / 66))
  readonly property real cardSize: 64

  function memText(mb) {
    return mb >= 1024 ? (mb / 1024).toFixed(1) + "G" : mb + "M"
  }

  Column {
    width: parent.width
    spacing: 8

    Process {
      running: root.visible
      command: ["python3",
        Qt.resolvedUrl("procs.py").toString().replace("file://", "")]
      stdout: SplitParser {
        onRead: function(line) {
          try {
            root.procs = JSON.parse(line).procs || []
          } catch (e) {}
        }
      }
    }

    Grid {
      columns: root.columns
      columnSpacing: 2
      rowSpacing: 8
      width: root.columns * root.cardSize + (root.columns - 1) * 2
      anchors.horizontalCenter: parent.horizontalCenter

      Repeater {
        model: root.procs

        Rectangle {
          required property var modelData
          required property int index
          readonly property var proc: modelData

          width: root.cardSize
          height: width
          color: Qt.alpha(pal.surface, 0.4)
          border.color: Qt.alpha(pal.structural, 0.55)
          border.width: 1
          clip: true

          Column {
            anchors {
              fill: parent
              margins: Math.max(4, width * 0.06)
            }
            spacing: 3

            Item {
              width: parent.width
              height: 9
              visible: root.cardSize >= 84

              Text {
                anchors.left: parent.left
                text: "0" + (index + 1)
                color: pal.mutedData
                font.family: "Blender Trial"
                font.pixelSize: 8
                font.letterSpacing: 1.2
              }

              Text {
                anchors.right: parent.right
                visible: proc.n > 1
                text: "×" + proc.n
                color: pal.mutedData
                font.family: "OCRA"
                font.pixelSize: 8
              }
            }

            Text {
              width: parent.width
              text: proc.name.toUpperCase()
              color: pal.accent
              font.family: "Blender Trial"
              font.pixelSize: root.cardSize >= 110 ? 11 : 9
              font.letterSpacing: 1
              elide: Text.ElideRight
            }

            Item { width: 1; height: root.cardSize >= 100 ? 4 : 1 }

            Text {
              text: proc.cpu.toFixed(0) + "%"
              color: proc.cpu > 90 ? pal.coralBright : pal.brightest
              font.family: "OCRA"
              font.pixelSize: root.cardSize >= 120 ? 20 : (root.cardSize >= 84 ? 15 : 11)
            }

            Text {
              visible: root.cardSize >= 84
              text: "CPU"
              color: pal.mutedData
              font.family: "Blender Trial"
              font.pixelSize: 7
              font.letterSpacing: 1.2
            }

            Item { width: 1; height: root.cardSize >= 100 ? 3 : 1 }

            Text {
              text: root.cardSize >= 84
                    ? proc.mem.toFixed(1) + "% · " + root.memText(proc.mb)
                    : root.memText(proc.mb)
              color: pal.readout
              font.family: "OCRA"
              font.pixelSize: 9
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              visible: root.cardSize >= 84
              text: "MEM"
              color: pal.mutedData
              font.family: "Blender Trial"
              font.pixelSize: 7
              font.letterSpacing: 1.2
            }
          }
        }
      }
    }

    Text {
      visible: root.procs.length === 0
      text: "NO LOAD"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.3
    }
  }
}
