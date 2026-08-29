import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Bare-minimum QuickShell bar, themed from wallust's generated palette.
//
// The palette is written by wallust (modules/wallust default.nix, template
// `quickshell.tmpl`) to ~/.config/quickshell/wallust-palette.json — the same
// palette that themes fuzzel / alacritty / niri, so the bar matches the rest
// of the system. We read it with Quickshell.Io/FileView (NOT the base
// `Quickshell` import — FileView lives in Quickshell.Io, which is exactly the
// `FileView is not a type` trap the old animated bar hit). watchChanges:true
// makes the bar follow wallpaper re-themes live, with no reload.
//
// Fallback colors stay as the old fixed values so the bar still renders before
// wallust has run once (or if the file is missing).
ShellRoot {
  // Resolve the palette path. The launcher (quickshell-bar wrapper) exports
  // QUICKSHELL_WALLUST_PALETTE; if absent, fall back to the canonical XDG
  // location so a manual `quickshell --path` run still finds it.
  readonly property string palettePath: (Quickshell.env("QUICKSHELL_WALLUST_PALETTE") || "").length > 0
    ? Quickshell.env("QUICKSHELL_WALLUST_PALETTE")
    : ((Quickshell.env("XDG_CONFIG_HOME") || "").length > 0
        ? Quickshell.env("XDG_CONFIG_HOME") + "/quickshell/wallust-palette.json"
        : Quickshell.env("HOME") + "/.config/quickshell/wallust-palette.json")

  readonly property string fallbackBg: "#0d0d14"
  readonly property string fallbackFg: "#e8e8f0"

  // Live theme colors. Start at fallbacks; overwritten once the palette loads.
  property string barBg: fallbackBg
  property string barFg: fallbackFg

  FileView {
    id: palette
    path: palettePath
    watchChanges: true

    onLoaded: {
      try {
        const p = JSON.parse(text());
        if (p.bg) barBg = p.bg;
        if (p.fg) barFg = p.fg;
      } catch (e) {
        // Leave fallbacks if the JSON is unreadable / malformed.
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
    implicitHeight: 34
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      color: barBg
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
        color: barFg
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
