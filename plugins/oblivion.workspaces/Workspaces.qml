import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Oblivion Signal workspaces — a clone of omarchy.workspaces re-drawn to the
// theme's component language: zero-padded readouts, a 1px rule under the
// focused cell, and a coral stepped flicker on urgent workspaces.
BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  function isUrgent(workspace) {
    if (!workspace || !workspace.toplevels) return false
    var tops = workspace.toplevels.values
    for (var i = 0; i < tops.length; i++) {
      if (tops[i].urgent) return true
    }
    return false
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: cell
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData
        readonly property bool urgent: !focused && root.isUrgent(workspace)
        property bool flickerOn: true

        bar: root.bar
        text: ("0" + modelData).slice(-2)
        // Inactive cells sit at muted-data level; the focused datum is bright.
        foreground: focused ? Color.bar.text : Qt.alpha(Color.bar.text, 0.6)
        active: urgent && flickerOn
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(24)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }

        // 1px rule under the active datum — coral when the cell is urgent.
        Rectangle {
          visible: cell.focused || cell.urgent
          anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 4
            rightMargin: 4
            bottomMargin: 2
          }
          height: 1
          color: cell.urgent ? Color.urgent : Color.accent
          opacity: cell.urgent ? (cell.flickerOn ? 1 : 0.35) : 1
        }

        // Stepped warn flicker — no easing, the film's motion is mechanical.
        Timer {
          interval: 500
          repeat: true
          running: cell.urgent
          onTriggered: cell.flickerOn = !cell.flickerOn
        }
      }
    }
  }
}
