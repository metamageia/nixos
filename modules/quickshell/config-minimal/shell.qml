import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Bare-minimum QuickShell bar: a single PanelWindow with a dark background and
// a live clock. No theming file, no file-watching color updates, no IPC bridge,
// no custom widget components — just a rendered baseline so we have a visible,
// loadable bar. Features are iterated back in one at a time.
ShellRoot {
  PanelWindow {
    id: bar
    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: 34
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      color: "#0d0d14"
      opacity: 0.88
      radius: 10

      Text {
        id: clock
        anchors {
          right: parent.right
          rightMargin: 12
          verticalCenter: parent.verticalCenter
        }
        text: Qt.formatDateTime(new Date(), "ddd HH:mm:ss")
        color: "#e8e8f0"
        font.family: "monospace"
        font.pixelSize: 13

        // Tick the clock once a second using only built-in QtQuick types.
        Timer {
          interval: 1000
          running: true
          repeat: true
          onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd HH:mm:ss")
        }
      }
    }
  }
}
