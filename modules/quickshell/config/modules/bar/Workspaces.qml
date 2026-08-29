import QtQuick
import QtQuick.Layouts
import Quickshell

// niri workspaces via qml-niri's WorkspaceModel (model: niri.workspaces).
// Roles: id, index, name, isActive, isFocused, isUrgent.
RowLayout {
  spacing: 6
  Repeater {
    model: niri.workspaces
    Rectangle {
      width: 16
      height: 16
      radius: 8
      color: model.isFocused ? colors.gold
        : (model.isActive ? colors.accent : "#2a2a3a")
      border.color: model.isUrgent ? colors.urgent : "transparent"
      border.width: model.isUrgent ? 2 : 0

      Text {
        anchors.centerIn: parent
        text: model.name !== "" ? model.name : (model.index + 1)
        color: (model.isFocused || model.isActive) ? "#0d0d14" : colors.muted
        font.pixelSize: 11
        font.bold: true
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: niri.focusWorkspaceById(model.id)
      }
    }
  }
}
