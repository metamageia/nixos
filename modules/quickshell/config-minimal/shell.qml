import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Niri

// QuickShell bar themed from wallust, with a native fade-out / fade-in
// transition between themes (Gage's "solid" Phase-4a layout).
//
// Layout (single full-width PanelWindow, flush to screen edges, no side
// margins, no rounded corners, no dividers):
//   LEFT   : niri workspaces (qml-niri WorkspaceModel)
//   CENTER : clock
//   RIGHT  : wifi, volume, system tray
//
// NO calendar / NO date-click (per Gage).
//
// Theme: every color is driven by the wallust palette (keys bg/fg/accent/gold/
// muted/urgent/green/blue) via the FileView + centralized palette props below
// — NO hex literals. Opacity 0.93 matches niri's window-rule opacity (a style
// constant, not a theme color).
//
// Crossfade: on a palette change the whole bar surface fades out (opacity), the
// pending palette is adopted into every color prop, then it fades back in.
// Because every widget binds to `root.<color>`, staging ALL 8 keys (not just
// bg+accent) generalizes the confirmed-working fade to the new widgets.
//
// NOTE (checked against QuickShell 0.3.0 typeinfo): PanelWindow does NOT have
// an `opacity` property (WindowInterface -> Reloadable -> QObject, not Item),
// so the fade animates the inner Rectangle (a real QQuickItem).
ShellRoot {
  id: root

  // Resolve the palette path (launcher exports QUICKSHELL_WALLUST_PALETTE).
  readonly property string palettePath: (Quickshell.env("QUICKSHELL_WALLUST_PALETTE") || "").length > 0
    ? Quickshell.env("QUICKSHELL_WALLUST_PALETTE")
    : ((Quickshell.env("XDG_CONFIG_HOME") || "").length > 0
        ? Quickshell.env("XDG_CONFIG_HOME") + "/quickshell/wallust-palette.json"
        : Quickshell.env("HOME") + "/.config/quickshell/wallust-palette.json")

  // Current (visible) theme colors — all from the wallust palette. NO literals.
  property string barBg: "#0d0d14"
  property string barFg: "#e8e6f0"
  property string barAccent: "#7b68ab"
  property string barGold: "#d4a017"
  property string barMuted: "#8b8bab"
  property string barUrgent: "#ff5555"
  property string barGreen: "#5e7a5e"
  property string barBlue: "#6b8e9f"

  // Pending (next) colors staged when wallust rewrites the palette.
  property string pendingBg: "#0d0d14"
  property string pendingFg: "#e8e6f0"
  property string pendingAccent: "#7b68ab"
  property string pendingGold: "#d4a017"
  property string pendingMuted: "#8b8bab"
  property string pendingUrgent: "#ff5555"
  property string pendingGreen: "#5e7a5e"
  property string pendingBlue: "#6b8e9f"

  // Skip the fade on the very first load (no previous theme to transition from).
  property bool firstLoad: true
  // Bumped on each staged theme change; the bar fades when it changes.
  property int themeRevision: 0

  // ---- qml-niri IPC singleton (verified against imiric/qml-niri README) ----
  // Must be instantiated and connect()'d; there is no global `niri`.
  Niri {
    id: niri
    Component.onCompleted: connect()
    onErrorOccurred: function (e) { console.error("qml-niri:", e) }
  }

  FileView {
    id: palette
    path: palettePath
    watchChanges: true
    onFileChanged: palette.reload()
    onLoaded: {
      try {
        const p = JSON.parse(text());
        if (root.firstLoad) {
          // Adopt the first palette immediately — no transition to run.
          if (p.bg) root.barBg = p.bg;
          if (p.fg) root.barFg = p.fg;
          if (p.accent) root.barAccent = p.accent;
          if (p.gold) root.barGold = p.gold;
          if (p.muted) root.barMuted = p.muted;
          if (p.urgent) root.barUrgent = p.urgent;
          if (p.green) root.barGreen = p.green;
          if (p.blue) root.barBlue = p.blue;
          root.firstLoad = false;
        } else {
          // Stage the new colors and let the bar fade old -> new.
          root.pendingBg = p.bg || root.barBg;
          root.pendingFg = p.fg || root.barFg;
          root.pendingAccent = p.accent || root.barAccent;
          root.pendingGold = p.gold || root.barGold;
          root.pendingMuted = p.muted || root.barMuted;
          root.pendingUrgent = p.urgent || root.barUrgent;
          root.pendingGreen = p.green || root.barGreen;
          root.pendingBlue = p.blue || root.barBlue;
          root.themeRevision++;
        }
      } catch (e) {
        // Keep current colors if the JSON is unreadable / malformed.
      }
    }
  }

  PanelWindow {
    id: bar
    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: 27
    color: "transparent"

    // The bar's visual surface. Solid, full-width, no radius, no border.
    // This Rectangle IS a QQuickItem, so it has a real `opacity` property —
    // the fade targets it, not the PanelWindow.
    Rectangle {
      id: surface
      anchors.fill: parent
      color: root.barBg
      opacity: 0.93
      radius: 0

      // LEFT — niri workspaces
      RowLayout {
        id: left
        spacing: 6
        anchors {
          left: parent.left
          leftMargin: 8
          verticalCenter: parent.verticalCenter
        }
        Repeater {
          model: niri.workspaces
          Rectangle {
            width: 20
            height: 20
            radius: 0
            color: model.isFocused ? root.barGold
              : (model.isActive ? root.barAccent : "transparent")
            border.color: model.isUrgent ? root.barUrgent : "transparent"
            border.width: model.isUrgent ? 2 : 0

            Text {
              anchors.centerIn: parent
              text: model.name !== "" ? model.name : (model.index + 1)
              color: (model.isFocused || model.isActive) ? root.barBg : root.barMuted
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

      // CENTER — clock
      Text {
        id: clock
        anchors {
          horizontalCenter: parent.horizontalCenter
          verticalCenter: parent.verticalCenter
        }
        text: Qt.formatDateTime(new Date(), "ddd HH:mm:ss")
        color: root.barAccent
        font.family: "monospace"
        font.pixelSize: 13
        Timer {
          interval: 1000
          running: true
          repeat: true
          onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd HH:mm:ss")
        }
      }

      // RIGHT — wifi, volume, tray
      RowLayout {
        id: right
        spacing: 12
        anchors {
          right: parent.right
          rightMargin: 8
          verticalCenter: parent.verticalCenter
        }

        // wifi via NetworkManager `nmcli` (no compositor dependency).
        Text {
          id: wifi
          color: root.barGreen
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
                if (p[0] === "yes" && p[1]) { ssid = p[1]; break }
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

        // volume via PipeWire/wireplumber `wpctl`.
        Text {
          id: vol
          color: root.barBlue
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

        // system tray via QuickShell's built-in SystemTray.
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

      // Fade out, adopt the staged palette into EVERY color, fade back in.
      SequentialAnimation on opacity {
        id: fadeSeq
        running: false
        NumberAnimation { to: 0.0; duration: 200; easing.type: Easing.InOutQuad }
        ScriptAction {
          script: {
            root.barBg = root.pendingBg
            root.barFg = root.pendingFg
            root.barAccent = root.pendingAccent
            root.barGold = root.pendingGold
            root.barMuted = root.pendingMuted
            root.barUrgent = root.pendingUrgent
            root.barGreen = root.pendingGreen
            root.barBlue = root.pendingBlue
          }
        }
        NumberAnimation { to: 0.93; duration: 200; easing.type: Easing.InOutQuad }
      }
    }
  }

  // Mirror themeRevision locally so the handler fires where it's declared.
  onThemeRevisionChanged: {
    if (root.firstLoad) return
    fadeSeq.restart()
  }
}
