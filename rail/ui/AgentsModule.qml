import QtQuick
import Quickshell
import Quickshell.Io

// AGENTS // LIVE — the last five running Devin sessions, each with the tail
// of its latest agent message. agents.py watches session_locks + transcripts
// and emits one JSON line per tick.
RailModule {
  id: root
  label: "AGENTS // LIVE"
  state: agents.length > 0 ? agents.length + " ACTIVE" : "IDLE"
  stateDot: agents.length > 0 ? pal.ok : pal.mutedData

  property var agents: []

  Column {
    width: parent.width
    spacing: 10

    Process {
      running: root.visible
      command: ["python3",
        Qt.resolvedUrl("agents.py").toString().replace("file://", "")]
      stdout: SplitParser {
        onRead: function(line) {
          try {
            root.agents = JSON.parse(line).agents || []
          } catch (e) {}
        }
      }
    }

    Repeater {
      model: root.agents

      Column {
        required property var modelData
        width: parent ? parent.width : 300
        spacing: 2

        Text {
          text: (modelData.kind === "codex" ? "CODEX — " : "DEVIN — ")
                + modelData.id.toUpperCase().replace(/-/g, "·")
          color: pal.accent
          font.family: "Blender Trial"
          font.pixelSize: 9
          font.letterSpacing: 1.3
        }

        Repeater {
          model: modelData.lines
          Text {
            required property string modelData
            width: parent.width
            text: modelData
            color: pal.mutedData
            font.family: "OCRA"
            font.pixelSize: 9
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }
      }
    }

    Text {
      visible: root.agents.length === 0
      text: "NO AGENTS RUNNING"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.3
    }
  }
}
