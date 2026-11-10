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
  property real maxHeight: Infinity
  height: Math.min(implicitHeight, maxHeight)
  clip: true

  readonly property var summaryFont: FontMetrics {
    font.family: "OCRA"
    font.pixelSize: 9
  }

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
        id: agentEntry
        required property var modelData
        readonly property real budget: Math.max(0,
          (root.maxHeight - 32 - 10 * (root.agents.length - 1)) / Math.max(1, root.agents.length))
        width: parent ? parent.width : 300
        height: Math.min(implicitHeight, budget)
        clip: true
        spacing: 2

        Text {
          id: agentHeading
          text: (modelData.kind === "codex" ? "CODEX — " : "DEVIN — ")
                + modelData.id.toUpperCase().replace(/-/g, "·")
          color: pal.accent
          font.family: "Blender Trial"
          font.pixelSize: 9
          font.letterSpacing: 1.3
        }

        Text {
          id: agentPrompt
          visible: modelData.prompt !== ""
          width: parent.width
          text: "> " + modelData.prompt
          color: pal.readout
          font.family: "OCRA"
          font.pixelSize: 9
          elide: Text.ElideRight
          maximumLineCount: 1
        }

        Repeater {
          // Drop transcript lines evenly across sessions, not whole agents.
          model: agentEntry.modelData.lines.slice(0, Math.max(0, Math.floor(
            (agentEntry.budget - agentHeading.height
             - (agentPrompt.visible ? agentPrompt.height + agentEntry.spacing : 0))
            / (root.summaryFont.height + agentEntry.spacing))))
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
