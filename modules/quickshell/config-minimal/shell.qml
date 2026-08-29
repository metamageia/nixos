import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// QuickShell bar themed from wallust, with a native fade-out / fade-in
// transition between themes. On a palette change the bar surface fades out,
// the new theme colors are adopted, then it fades back in. Uses only built-in
// QtQuick (opacity + NumberAnimation) — no shader, no .qsb, no build toolchain.
//
// NOTE (checked against Quickshell 0.3.0 typeinfo): PanelWindow does NOT have
// an `opacity` property (its prototype chain is WindowInterface -> Reloadable
// -> QObject, not Item). So the fade animates the inner Rectangle, which IS a
// QQuickItem and has real opacity.
ShellRoot {
  id: root

  // Resolve the palette path (launcher exports QUICKSHELL_WALLUST_PALETTE).
  readonly property string palettePath: (Quickshell.env("QUICKSHELL_WALLUST_PALETTE") || "").length > 0
    ? Quickshell.env("QUICKSHELL_WALLUST_PALETTE")
    : ((Quickshell.env("XDG_CONFIG_HOME") || "").length > 0
        ? Quickshell.env("XDG_CONFIG_HOME") + "/quickshell/wallust-palette.json"
        : Quickshell.env("HOME") + "/.config/quickshell/wallust-palette.json")

  // Current (visible) theme colors.
  property string barBg: "#0d0d14"
  property string barAccent: "#7b68ab"

  // Pending (next) colors staged when wallust rewrites the palette.
  property string pendingBg: "#0d0d14"
  property string pendingAccent: "#7b68ab"

  // Skip the fade on the very first load (no previous theme to transition from).
  property bool firstLoad: true

  // Bumped on each staged theme change; the bar fades when it changes.
  property int themeRevision: 0

  // One clock string shared so the bar ticks in one place.
  property string clockText: Qt.formatDateTime(new Date(), "ddd HH:mm:ss")
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.clockText = Qt.formatDateTime(new Date(), "ddd HH:mm:ss")
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
          if (p.accent) root.barAccent = p.accent;
          root.firstLoad = false;
        } else {
          // Stage the new colors and let the bar fade old -> new.
          root.pendingBg = p.bg || root.barBg;
          root.pendingAccent = p.accent || root.barAccent;
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
    implicitHeight: 34
    color: "transparent"

    // The bar's visual surface. This Rectangle IS a QQuickItem, so it has a
    // real `opacity` property — the fade targets it, not the PanelWindow.
    Rectangle {
      id: surface
      anchors.fill: parent
      color: root.barBg
      opacity: 0.88
      radius: 10

      Text {
        id: clock
        anchors {
          right: parent.right
          rightMargin: 12
          verticalCenter: parent.verticalCenter
        }
        text: root.clockText
        color: root.barAccent
        font.family: "monospace"
        font.pixelSize: 13
      }

      // Fade out, adopt the new theme, fade back in.
      SequentialAnimation on opacity {
        id: fadeSeq
        running: false
        NumberAnimation { to: 0.0; duration: 200; easing.type: Easing.InOutQuad }
        ScriptAction {
          script: {
            root.barBg = root.pendingBg;
            root.barAccent = root.pendingAccent;
          }
        }
        NumberAnimation { to: 0.88; duration: 200; easing.type: Easing.InOutQuad }
      }
    }
  }

  // Mirror themeRevision locally so the handler fires where it's declared.
  onThemeRevisionChanged: {
    if (root.firstLoad) return;
    surface.fadeSeq.restart();
  }
}
