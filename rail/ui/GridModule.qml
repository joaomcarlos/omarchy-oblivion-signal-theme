import QtQuick
import QtQuick.Shapes

// COORD // GRID — a survey reticle: hairline grid, coverage sector, target
// rings with crosshair, one coral anomaly marker, cardinal labels, and a slow
// scan sweep. Coordinates drift gently for flavor.
RailModule {
  id: root
  label: "COORD // GRID"
  state: coords

  property string coords: "N 47.30 W 122.10"

  Item {
    id: grid
    width: parent.width
    height: width * 0.5

    Timer {
      interval: 5000
      repeat: true
      running: root.visible
      onTriggered: {
        var lat = 47.3 + (Math.random() - 0.5) * 0.12
        var lon = 122.1 + (Math.random() - 0.5) * 0.12
        root.coords = "N " + lat.toFixed(2) + " W " + lon.toFixed(2)
      }
    }

    // hairline grid — 5 horizontal + 5 vertical lines
    Repeater {
      model: 5
      Rectangle {
        x: 0
        y: grid.height * (index + 1) / 6
        width: grid.width
        height: 1
        color: Qt.alpha(pal.structural, 0.3)
      }
    }
    Repeater {
      model: 5
      Rectangle {
        x: grid.width * (index + 1) / 6
        y: 0
        width: 1
        height: grid.height
        color: Qt.alpha(pal.structural, 0.3)
      }
    }

    // coverage sector — translucent wedge above the center point
    Shape {
      anchors.fill: parent

      ShapePath {
        strokeColor: Qt.alpha(pal.accent, 0.3)
        strokeWidth: 1
        fillColor: Qt.alpha(pal.accent, 0.08)
        startX: grid.width / 2
        startY: grid.height / 2

        PathLine { x: grid.width * 0.33; y: grid.height * 0.16 }
        PathLine { x: grid.width * 0.67; y: grid.height * 0.16 }
        PathLine { x: grid.width / 2; y: grid.height / 2 }
      }
    }

    // target rings + crosshair at the center point
    Rectangle {
      anchors.centerIn: parent
      width: 30
      height: 30
      radius: 15
      color: "transparent"
      border.width: 1
      border.color: Qt.alpha(pal.accent, 0.5)
    }
    Rectangle {
      anchors.centerIn: parent
      width: 16
      height: 16
      radius: 8
      color: "transparent"
      border.width: 1
      border.color: Qt.alpha(pal.bright, 0.6)
    }
    Rectangle {
      anchors.centerIn: parent
      width: 1
      height: 24
      color: Qt.alpha(pal.accent, 0.4)
    }
    Rectangle {
      anchors.centerIn: parent
      width: 24
      height: 1
      color: Qt.alpha(pal.accent, 0.4)
    }

    // coral anomaly marker — outlined square with an X
    Item {
      x: grid.width * 0.70
      y: grid.height * 0.60
      width: 10
      height: 10
      opacity: 0.75

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

    // cardinal markers
    Text {
      anchors { top: parent.top; topMargin: 3; horizontalCenter: parent.horizontalCenter }
      text: "N"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 8
    }
    Text {
      anchors { bottom: parent.bottom; bottomMargin: 3; horizontalCenter: parent.horizontalCenter }
      text: "S"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 8
    }
    Text {
      anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
      text: "W"
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 8
    }
    Text {
      anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
      text: "E"
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
