import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// QuickShell bar themed from wallust, with a native fade-out / fade-in
// transition between themes. On a palette change the whole bar fades out,
// the new theme colors are adopted, then it fades back in. Uses only built-in
// QtQuick (opacity + NumberAnimation) — no shader, no .qsb, no build toolchain.
ShellRoot {
  id: root

  // Resolve the palette path (launcher exports QUICKSHELL_WALLUST_PALETTE).
  readonly property string palettePath: (Quickshell.env("QUICKSHELL_WALLUST_PALETTE") || "").length > 0
    ? Quickshell.env("QUICKSHELL_WALLUST_PALETTE")
    : ((Quickshell.env("XDG_CONFIG_HOME") || "").length > 0
        ? Quickshell.env("XDG_CONFIG_HOME") + "/quickshell/wallust-palette.json"
        : Quickshell.env("HOME") + "/.config/quickshell/wallust-palette.json")

  // Current (visible) theme colors, owned by the ShellRoot so the FileView and
  // the bar can both reach them.
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

    // Mirror the ShellRoot's theme values onto the bar so its bindings and the
    // fade sequence can reference them locally, and so onThemeRevisionChanged
    // fires on this object (a handler needs the property declared here).
    property string barBg: root.barBg
    property string barAccent: root.barAccent
    property string pendingBg: root.pendingBg
    property string pendingAccent: root.pendingAccent
    property int themeRevision: root.themeRevision
    property int lastRevision: 0

    onThemeRevisionChanged: {
      if (themeRevision === lastRevision) return;
      lastRevision = themeRevision;
      // Capture the staged colors, then fade out -> adopt -> fade in.
      pendingBg = root.pendingBg;
      pendingAccent = root.pendingAccent;
      fadeSeq.restart();
    }

    // The bar's single visual surface. Colors bind to the current theme.
    Rectangle {
      anchors.fill: parent
      color: bar.barBg
      opacity: 0.88
      radius: 10
      Text {
        anchors {
          right: parent.right
          rightMargin: 12
          verticalCenter: parent.verticalCenter
        }
        text: root.clockText
        color: bar.barAccent
        font.family: "monospace"
        font.pixelSize: 13
      }
    }

    // Fade the whole bar out, adopt the new theme, fade back in.
    SequentialAnimation on opacity {
      id: fadeSeq
      running: false
      NumberAnimation { to: 0.0; duration: 200; easing.type: Easing.InOutQuad }
      ScriptAction {
        script: {
          bar.barBg = bar.pendingBg;
          bar.barAccent = bar.pendingAccent;
        }
      }
      NumberAnimation { to: 1.0; duration: 200; easing.type: Easing.InOutQuad }
    }
  }
}
