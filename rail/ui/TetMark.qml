import QtQuick

// TET-style brand mark — a diamond inside a square, outlined, not filled.
Item {
  id: root
  property var pal: null
  property bool muted: true
  property bool pulse: true
  property bool beat: true

  implicitWidth: 10
  implicitHeight: 10
  opacity: pulse ? (beat ? 1 : 0.6) : 1

  readonly property color markColor: muted ? pal.structural : pal.accent

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.width: 1
    border.color: root.markColor
  }

  Rectangle {
    width: 4
    height: 4
    anchors.centerIn: parent
    rotation: 45
    color: "transparent"
    border.width: 1
    border.color: root.markColor
  }

  Timer {
    interval: 2000
    repeat: true
    running: root.pulse && root.visible
    onTriggered: root.beat = !root.beat
  }
}
