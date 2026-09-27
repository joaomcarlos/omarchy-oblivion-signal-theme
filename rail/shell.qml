import QtQuick
import Quickshell
import Quickshell.Wayland
import "ui"

// Oblivion Signal telemetry rail — a standalone Quickshell instance that draws
// the theme's peripheral instruments in the right-hand workspace gap.
// Launch with: quickshell -p <path-to-rail>
ShellRoot {
  id: shell

  // Shared instances injected into every module — one FileView on
  // colors.toml, one poll.sh process feeding all readouts.
  property var pal: Palette {}
  property var vitals: Vitals {}

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        right: true
        bottom: true
      }
      margins {
        top: 40
        right: 18
        bottom: 16
      }
      implicitWidth: 356
      color: "#ff0000"
      exclusionMode: ExclusionMode.Ignore

      WlrLayershell.namespace: "oblivion-rail"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      // No input region — the rail is read-only instrumentation; clicks fall
      // through to whatever is beneath it.
      mask: Region {}

      Column {
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
        }
        spacing: 24

        SignalModule {
          pal: shell.pal
          vitals: shell.vitals
        }
        VitalsModule {
          pal: shell.pal
          vitals: shell.vitals
        }
        TraceModule {
          pal: shell.pal
          vitals: shell.vitals
        }
      }
    }
  }
}
