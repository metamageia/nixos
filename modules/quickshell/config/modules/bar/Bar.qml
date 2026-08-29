import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Top status bar. `colors` and `niri` are inherited from shell.qml's scope.
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
    color: colors.bg
    opacity: 0.88
    radius: 10

    // left: niri workspaces
    RowLayout {
      anchors {
        left: parent.left
        leftMargin: 12
        verticalCenter: parent.verticalCenter
      }
      spacing: 10
      Loader { active: true; sourceComponent: Workspaces {} }
    }

    // center: focused window title
    Text {
      id: title
      anchors {
        horizontalCenter: parent.horizontalCenter
        verticalCenter: parent.verticalCenter
      }
      text: niri.focusedWindow ? niri.focusedWindow.title : ""
      color: colors.muted
      font.family: "Inter"
      font.pixelSize: 13
      elide: Text.ElideRight
      maximumLineCount: 1
      width: Math.min(parent.width * 0.4, 420)
    }

    // right: wifi, volume, tray, clock
    RowLayout {
      anchors {
        right: parent.right
        rightMargin: 12
        verticalCenter: parent.verticalCenter
      }
      spacing: 12
      Loader { active: true; sourceComponent: Wifi {} }
      Loader { active: true; sourceComponent: Volume {} }
      Loader { active: true; sourceComponent: Tray {} }
      Loader { active: true; sourceComponent: Clock {} }
    }
  }
}
