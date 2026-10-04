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
    if (v < 1048576) return (v / 1024).toFixed(1) + " kb/s"
    if (v < 1073741824) return (v / 1048576).toFixed(1) + " mb/s"
    return (v / 1073741824).toFixed(2) + " gb/s"
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
    visible: vitals.gpu >= 0
    pal: root.pal
    vitals: root.vitals
    label: "GPU"
    rightContent: gpuRail

    Component {
      id: gpuRail
      Row {
        spacing: 7

        Text {
          text: vitals.gtemp >= 0 ? vitals.gtemp + "°C · " + vitals.gpu + "%" : vitals.gpu + "%"
          color: vitals.gpu > 90 || vitals.gtemp > 85 ? pal.coralBright : pal.readout
          font.family: "OCRA"
          font.pixelSize: 11
          anchors.verticalCenter: parent.verticalCenter
        }

        Row {
          spacing: 1
          anchors.verticalCenter: parent.verticalCenter

          Repeater {
            model: 10
            Rectangle {
              required property int index
              readonly property bool on: index < Math.round(vitals.gpu / 10)
              width: 3
              height: 8
              color: on ? (vitals.gpu > 90 && index >= 8 ? pal.coral : pal.accent)
                        : Qt.alpha(pal.structural, 0.4)
            }
          }
        }
      }
    }
  }

  VitalRow {
    visible: vitals.vram >= 0
    pal: root.pal
    vitals: root.vitals
    label: "GPU - VRAM"
    rightContent: vramRail

    Component {
      id: vramRail
      Row {
        spacing: 7

        Text {
          text: vitals.vram + "%"
          color: vitals.vram > 90 ? pal.coralBright : pal.readout
          font.family: "OCRA"
          font.pixelSize: 11
          anchors.verticalCenter: parent.verticalCenter
        }

        Row {
          spacing: 1
          anchors.verticalCenter: parent.verticalCenter

          Repeater {
            model: 10
            Rectangle {
              required property int index
              readonly property bool on: index < Math.round(vitals.vram / 10)
              width: 3
              height: 8
              color: on ? (vitals.vram > 90 && index >= 8 ? pal.coral : pal.accent)
                        : Qt.alpha(pal.structural, 0.4)
            }
          }
        }
      }
    }
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "CPU"
    rightContent: cpuRail

    Component {
      id: cpuRail
      Row {
        spacing: 7

        Text {
          text: vitals.temp >= 0 ? vitals.temp + "°C · " + vitals.cpu + "%" : vitals.cpu + "%"
          color: vitals.cpu > 90 || vitals.temp > 85 ? pal.coralBright : pal.readout
          font.family: "OCRA"
          font.pixelSize: 11
          anchors.verticalCenter: parent.verticalCenter
        }

        Row {
          spacing: 1
          anchors.verticalCenter: parent.verticalCenter

          Repeater {
            model: 10
            Rectangle {
              required property int index
              readonly property bool on: index < Math.round(vitals.cpu / 10)
              width: 3
              height: 8
              color: on ? (vitals.cpu > 90 && index >= 8 ? pal.coral : pal.accent)
                        : Qt.alpha(pal.structural, 0.4)
            }
          }
        }
      }
    }

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
        spacing: 7

        Text {
          text: vitals.mem + "%"
          color: vitals.mem > 90 ? pal.coralBright : pal.readout
          font.family: "OCRA"
          font.pixelSize: 11
          anchors.verticalCenter: parent.verticalCenter
        }

        Row {
          spacing: 1
          anchors.verticalCenter: parent.verticalCenter

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
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "NET"
    rightContent: netRail

    Component {
      id: netRail
      Item {
        width: 150
        height: 16

        Text {
          anchors {
            right: arrows.left
            rightMargin: 5
            verticalCenter: parent.verticalCenter
          }
          text: root.rate(vitals.tx)
          color: pal.readout
          font.family: "OCRA"
          font.pixelSize: 11
        }
        Text {
          id: arrows
          anchors.centerIn: parent
          text: "↑↓"
          color: pal.accent
          font.family: "OCRA"
          font.pixelSize: 11
        }
        Text {
          anchors {
            left: arrows.right
            leftMargin: 5
            verticalCenter: parent.verticalCenter
          }
          text: root.rate(vitals.rx)
          color: pal.readout
          font.family: "OCRA"
          font.pixelSize: 11
        }
      }
    }
  }

  VitalRow {
    pal: root.pal
    vitals: root.vitals
    label: "DISK"
    value: vitals.disk + "%"
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
