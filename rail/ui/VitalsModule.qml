import QtQuick

// TET SYSTEM // VITALS — real system readouts from poll.sh. The module state
// flips to coral DEGRADED when any reading crosses its threshold.
RailModule {
  id: root
  label: "SYSTEM // VITALS"
  state: vitals.degraded ? "DEGRADED" : "NOMINAL"
  alert: vitals.degraded
  headerPrefix: tetHeader

  function rate(v) {
    if (v < 1024) return v + "B/s"
    if (v < 1048576) return Math.round(v / 1024) + "KB/s"
    if (v < 1073741824) return (v / 1048576).toFixed(1) + "MB/s"
    return (v / 1073741824).toFixed(2) + "GB/s"
  }

  component VitalRow: Item {
    property var pal: null
    property var vitals: null
    property string label: ""
    property string value: ""
    property string valueFont: "OCRA"
    property real valueSize: 11
    property bool alarming: false
    property Component rightContent: null

    width: parent ? parent.width : 300
    height: 16

    Text {
      anchors {
        left: parent.left
        verticalCenter: parent.verticalCenter
      }
      text: label
      color: pal.mutedData
      font.family: "Blender Trial"
      font.pixelSize: 9
      font.letterSpacing: 1.4
    }

    Loader {
      anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
      }
      sourceComponent: rightContent
    }

    Text {
      anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
      }
      visible: rightContent === null
      text: value
      color: alarming ? pal.coralBright : pal.readout
      font.family: valueFont
      font.pixelSize: valueSize
    }
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "CPU"
    value: vitals.temp >= 0 ? vitals.temp + "°C · " + vitals.cpu + "%" : vitals.cpu + "%"
    alarming: vitals.cpu > 90 || vitals.temp > 85

    Component {
      id: tetHeader
      Row {
        spacing: 6

        TetMark {
          muted: true
          pal: root.pal
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: "TET"
          color: pal.accent
          font.family: "Blender Trial"
          font.pixelSize: 11
          font.letterSpacing: 2
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "MEM"
    rightContent: memRail

    Component {
      id: memRail
      Row {
        spacing: 1

        Repeater {
          model: 10
          Rectangle {
            required property int index
            readonly property bool on: index < Math.round(vitals.mem / 10)
            width: 3
            height: 8
            color: on ? (vitals.mem > 90 && index >= 8 ? pal.coral : pal.accent)
                      : Qt.alpha(pal.structural, 0.4)
          }
        }
      }
    }
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "NET"
    value: root.rate(vitals.tx) + "↑ " + root.rate(vitals.rx) + "↓"
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "PWR"
    value: vitals.pwr === "AC" ? "AC" : vitals.pwr + "%"
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "DISK"
    value: "/ " + vitals.disk + "%"
    alarming: vitals.disk > 90
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "UPTIME"
    value: vitals.up
    valueFont: "DSEG7 Classic"
    valueSize: 10
  }
}
