import QtQuick
import Quickshell

// Clock via QuickShell's built-in SystemClock (auto-updates on date change).
Text {
  id: clock
  color: colors.fg
  font.family: "Inter"
  font.pixelSize: 13
  font.bold: true

  SystemClock {
    id: clk
    precision: SystemClock.Seconds
  }

  text: Qt.formatDateTime(clk.date, "HH:mm  dd MMM")
}
