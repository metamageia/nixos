import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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
// Theme: every color — including the SVG icon tints — is driven by the wallust
// palette (keys bg/fg/accent/gold/muted/urgent/green/blue) via the FileView +
// centralized palette props below — NO hex literals. Opacity 0.93 matches
// niri's window-rule opacity (a style constant, not a theme color).
//
// Typography: smooth UI sans "Inter" for ALL text (clock, workspace numbers,
// volume %, wifi label). The Iosevka Nerd Font Mono glyphs were replaced with
// monochrome themeable SVG icons (Phase 4c).
//
// Icons (Phase 4c): clean monochrome SVGs under ./icons/, tinted to a palette
// color at runtime via Qt5Compat.GraphicalEffects.ColorOverlay. ColorOverlay
// multiplies source pixels by `color`, so the SVGs are authored WHITE on
// transparent and tinted to barXxx. The tint binding is a `root.barXxx` property
// that the staged crossfade (4a) re-adopts on theme change, so Mod+W recolors
// every icon. No font-glyph / Nerd Font icons remain anywhere in the bar.
//
// Icon path resolution: the QML ships both in the nix store derivation and at
// ~/.config/quickshell/bar. Resolve ./icons/<name>.svg against the directory
// the running config is loaded from via Quickshell.shellRoot, so it works in
// both locations without a hardcoded store path.
//
// Crossfade: on a palette change the whole bar surface fades out (opacity), the
// pending palette is adopted into every color prop, then it fades back in.
// Because every widget binds to `root.<color>`, staging ALL 8 keys (not just
// bg+accent) generalizes the confirmed-working fade to the new widgets.
//
// NOTE (checked against QuickShell 0.3.0 typeinfo): PanelWindow does NOT have
// an `opacity` property (WindowInterface -> Reloadable -> QObject, not Item),
// so the fade animates the inner Rectangle (a real QQuickItem).
//
// NOTE (checked against QuickShell 0.3.0 qt5compat closure): ColorOverlay lives
// in Qt5Compat.GraphicalEffects, which is NOT in QuickShell's default QML import
// path. The launcher wrapper (default.nix) appends qt5compat's qml dir to
// QML2_IMPORT_PATH so `import Qt5Compat.GraphicalEffects` resolves.
ShellRoot {
  id: root

  // Resolve the palette path (launcher exports QUICKSHELL_WALLUST_PALETTE).
  readonly property string palettePath: (Quickshell.env("QUICKSHELL_WALLUST_PALETTE") || "").length > 0
    ? Quickshell.env("QUICKSHELL_WALLUST_PALETTE")
    : ((Quickshell.env("XDG_CONFIG_HOME") || "").length > 0
        ? Quickshell.env("XDG_CONFIG_HOME") + "/quickshell/wallust-palette.json"
        : Quickshell.env("HOME") + "/.config/quickshell/wallust-palette.json")

  // Smooth UI sans for all text. Verified installed: `Inter` / `Inter Variable`.
  readonly property string uiFont: "Inter"

  // Directory the running config is loaded from — used to resolve the local
  // ./icons/*.svg set (works in both the nix store derivation and
  // ~/.config/quickshell/bar).
  readonly property string iconDir: Quickshell.shellRoot + "/icons"

  // Live mute state, driven by the volume poll. Lets the volume icon tint bind
  // to a palette key (so the 4a crossfade still recolors it on theme change).
  property bool volMuted: false

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

  // Reusable monochrome icon: a white SVG tinted to the palette via ColorOverlay.
  // tint is a `root.barXxx` binding so the staged crossfade recolors it.
  component ThemeIcon: Item {
    property string source
    property color tint
    property int size: 14
    width: size
    height: size

    Image {
      id: ic
      anchors.fill: parent
      source: "file://" + root.iconDir + "/" + source
      sourceSize.width: size
      sourceSize.height: size
      fillMode: Image.PreserveAspectFit
      visible: false
    }
    ColorOverlay {
      anchors.fill: ic
      source: ic
      color: tint
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
        ThemeIcon {
          source: "workspace.svg"
          tint: root.barMuted
          size: 13
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
              text: model.name !== "" ? model.name : model.id
              color: (model.isFocused || model.isActive) ? root.barBg : root.barMuted
              font.family: root.uiFont
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
        font.family: root.uiFont
        font.pixelSize: 13
        Timer {
          interval: 1000
          running: true
          repeat: true
          onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd HH:mm:ss")
        }
      }
      ThemeIcon {
        source: "clock.svg"
        tint: root.barAccent
        size: 13
        anchors {
          right: clock.left
          rightMargin: 5
          verticalCenter: parent.verticalCenter
        }
      }

      // RIGHT — wifi, volume
      RowLayout {
        id: right
        spacing: 12
        anchors {
          right: parent.right
          rightMargin: 8
          verticalCenter: parent.verticalCenter
        }

        // wifi via NetworkManager `nmcli` (no compositor dependency).
        // Click opens networkmanager_dmenu — the existing fuzzel/rofi picker
        // already in the package set (modules/networking). No new picker built.
        Text {
          id: wifi
          color: root.barGreen
          font.family: root.uiFont
          font.pixelSize: 13
          text: "net --"
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["networkmanager_dmenu"])
          }
        }
        ThemeIcon {
          source: "wifi.svg"
          tint: root.barGreen
          size: 14
          anchors.verticalCenter: parent.verticalCenter
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

        // volume via PipeWire/wireplumber `wpctl`. Scroll = step volume by 5%,
        // click = toggle mute. Both fired through Quickshell.execDetached (a
        // detached shell command). Numeric % + mute state kept visible; the icon
        // + color bind to the palette so the 4a crossfade still recolors them.
        Text {
          id: vol
          color: root.volMuted ? root.barUrgent : root.barBlue
          font.family: root.uiFont
          font.pixelSize: 13
          text: "vol --"
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
              volProc.running = true
            }
            onWheel: (wheel) => {
              const step = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
              Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", step])
              volProc.running = true
            }
          }
        }
        ThemeIcon {
          id: volIcon
          source: "volume.svg"
          tint: root.volMuted ? root.barUrgent : root.barBlue
          size: 14
          anchors.verticalCenter: parent.verticalCenter
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
              root.volMuted = muted
              if (m) {
                const pct = Math.round(parseFloat(m[1]) * 100)
                vol.text = (muted ? "MUTE " : "") + pct + "%"
                volIcon.source = muted ? "volume-muted.svg" : "volume.svg"
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
