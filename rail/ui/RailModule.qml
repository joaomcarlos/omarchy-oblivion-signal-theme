import QtQuick

// Shared frame for rail modules: an uppercase label left, a state readout
// right, a structural hairline underneath, then the module content.
Item {
  id: root

  default property alias content: contentColumn.children
  // Injected from shell.qml — shared instances, one FileView and one poller.
  property var pal: null
  property var vitals: null
  property string label: ""
  property string state: ""
  property bool alert: false
  property color stateDot: "transparent"
  property Component headerPrefix: null

  implicitWidth: parent ? parent.width : 300
  implicitHeight: layout.implicitHeight

  Column {
    id: layout
    anchors {
      left: parent.left
      right: parent.right
    }
    spacing: 6

    Item {
      width: parent.width
      height: headerRow.implicitHeight + 8

      Row {
        id: headerRow
        spacing: 6

        Loader {
          sourceComponent: root.headerPrefix
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: root.label
          color: pal.mutedData
          font.family: "Blender Trial"
          font.pixelSize: 10
          font.letterSpacing: 1.4
          font.capitalization: Font.AllUppercase
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Row {
        anchors {
          right: parent.right
          verticalCenter: parent.verticalCenter
        }
        spacing: 5

        Rectangle {
          width: 5
          height: 5
          radius: 0
          color: root.stateDot
          visible: root.stateDot.a > 0
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: root.state
          color: root.alert ? pal.coral : pal.mutedData
          font.family: "OCRA"
          font.pixelSize: 10
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Rectangle {
        anchors {
          left: parent.left
          right: parent.right
          bottom: parent.bottom
        }
        height: 1
        color: Qt.alpha(pal.structural, 0.35)
      }
    }

    Column {
      id: contentColumn
      width: parent.width
      spacing: 3
    }
  }
}
