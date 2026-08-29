import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Volume via PipeWire/wireplumber `wpctl` (reliable; already in the stack).
// wpctl get-volume prints e.g. "Volume: 0.45" or "Volume: 0.45 [MUTED]".
RowLayout {
  spacing: 4
  Text {
    id: vol
    color: colors.blue
    font.family: "Inter"
    font.pixelSize: 13
    text: "vol --"
  }

  Process {
    id: volProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const t = this.text.trim()
        const m = t.match(/Volume:\s*([\d.]+)/)
        const muted = /MUTED/.test(t)
        if (m) {
          const pct = Math.round(parseFloat(m[1]) * 100)
          vol.text = (muted ? "mute " : "vol ") + pct + "%"
        } else {
          vol.text = "vol ?"
        }
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: volProc.running = true
  }
}
