import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

// System tray via QuickShell's built-in SystemTray (freedesktop StatusNotifier).
// Referencing SystemTray.items makes QuickShell start tracking tray contents.
RowLayout {
  spacing: 6
  Repeater {
    model: SystemTray.items
    Image {
      source: modelData.icon
      width: 16
      height: 16
      fillMode: Image.PreserveAspectFit

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: modelData.activate()
      }
    }
  }
}
