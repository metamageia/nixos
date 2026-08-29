import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// WiFi via NetworkManager `nmcli` (generic, no Hyprland dependency).
// `nmcli -t -f active,ssid dev wifi` lists "yes:<SSID>" for the connected AP.
RowLayout {
  spacing: 4
  Text {
    id: wifi
    color: colors.green
    font.family: "Inter"
    font.pixelSize: 13
    text: "net --"
  }

  Process {
    id: wifiProc
    command: ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = this.text.split("\n")
        let ssid = ""
        for (const l of lines) {
          const p = l.split(":")
          if (p[0] === "yes" && p[1]) {
            ssid = p[1]
            break
          }
        }
        wifi.text = ssid ? ("net " + ssid) : "net off"
      }
    }
  }

  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: wifiProc.running = true
  }
}
