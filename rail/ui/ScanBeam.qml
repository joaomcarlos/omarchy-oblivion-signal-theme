import QtQuick

// A bright scan line sweeping an area right-to-left in discrete steps — the
// mockup's scan-sweep is steps(8), so the beam jumps rather than glides.
Item {
  id: root
  property var pal: null
  property int step: 0
  property int steps: 9
  property int interval: 400
  clip: true

  Timer {
    interval: root.interval
    repeat: true
    running: root.visible
    onTriggered: root.step = (root.step + 1) % root.steps
  }

  Row {
    // Beam travels right edge -> left edge, 10px wide total.
    x: (root.width + 10) * (1 - root.step / (root.steps - 1)) - 5
    height: root.height

    Rectangle { width: 4; height: parent.height; color: Qt.alpha(pal.accent, 0.18) }
    Rectangle { width: 2; height: parent.height; color: Qt.alpha(pal.bright, 0.55) }
    Rectangle { width: 4; height: parent.height; color: Qt.alpha(pal.accent, 0.18) }
  }
}
