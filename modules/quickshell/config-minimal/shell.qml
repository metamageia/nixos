import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// QuickShell bar themed from wallust, with a hard 45° diagonal wipe between
// themes (matches the awww wallpaper wipe: --transition-angle 45, no color
// tween/fade). On a palette change we stage the next theme as a second layer
// and a ShaderEffect composites old-over-new behind a 45° boundary whose
// position sweeps linearly; at the end the new theme is committed as the base.
ShellRoot {
  id: root

  // Resolve the palette path (launcher exports QUICKSHELL_WALLUST_PALETTE).
  readonly property string palettePath: (Quickshell.env("QUICKSHELL_WALLUST_PALETTE") || "").length > 0
    ? Quickshell.env("QUICKSHELL_WALLUST_PALETTE")
    : ((Quickshell.env("XDG_CONFIG_HOME") || "").length > 0
        ? Quickshell.env("XDG_CONFIG_HOME") + "/quickshell/wallust-palette.json"
        : Quickshell.env("HOME") + "/.config/quickshell/wallust-palette.json")

  readonly property string fallbackBg: "#0d0d14"
  readonly property string fallbackAccent: "#7b68ab"

  // Current (visible) theme colors.
  property string barBg: fallbackBg
  property string barAccent: fallbackAccent

  // Pending (next) theme colors — the wipe reveals these over the current ones.
  property string pendingBg: fallbackBg
  property string pendingAccent: fallbackAccent

  // Skip the wipe on the very first load (no previous theme to wipe from).
  property bool firstLoad: true

  // Bumped on each staged theme change; the bar wipes when it changes.
  property int themeRevision: 0

  // One clock string shared by both layers so they tick in lockstep.
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
          // Adopt the first palette immediately — no wipe to run.
          if (p.bg) root.barBg = p.bg;
          if (p.accent) root.barAccent = p.accent;
          root.firstLoad = false;
        } else {
          // Stage the next theme and let the bar wipe old -> new.
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

    // Fire the wipe whenever a new theme is staged. themeRevision lives on the
    // ShellRoot (root); mirror it here so this PanelWindow has the property and
    // its on<Property>Changed signal fires locally.
    property int themeRevision: root.themeRevision
    property int lastRevision: 0
    onThemeRevisionChanged: {
      if (themeRevision === lastRevision) return;
      lastRevision = themeRevision;
      pendingLayer.visible = true;
      wipeOverlay.visible = true;
      wipeAnim.restart();
    }

    // Layer 0 — the current theme (the normal bar).
    Item {
      id: currentLayer
      anchors.fill: parent
      Rectangle {
        anchors.fill: parent
        color: root.barBg
        opacity: 0.88
        radius: 10
        Text {
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
      }
    }

    // Layer 1 — the pending theme, revealed by the wipe shader.
    Item {
      id: pendingLayer
      anchors.fill: parent
      visible: false
      Rectangle {
        anchors.fill: parent
        color: root.pendingBg
        opacity: 0.88
        radius: 10
        Text {
          anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
          }
          text: root.clockText
          color: root.pendingAccent
          font.family: "monospace"
          font.pixelSize: 13
        }
      }
    }

    // Wipe overlay: composites current + pending behind a hard 45° edge.
    // Edge is the line (x - y) = split; sweeping split -2..2 moves it across.
    ShaderEffect {
      id: wipeOverlay
      anchors.fill: parent
      visible: false
      property real progress: 0.0
      property variant source: currentLayer
      property variant newSource: pendingLayer
      fragmentShader: "
        varying vec2 qt_TexCoord0;
        uniform float progress;
        uniform sampler2D source;
        uniform sampler2D newSource;
        void main() {
          vec4 cur = texture2D(source, qt_TexCoord0);
          vec4 neu = texture2D(newSource, qt_TexCoord0);
          float b = qt_TexCoord0.x - qt_TexCoord0.y;
          float split = mix(-2.0, 2.0, progress);
          gl_FragColor = (b < split) ? neu : cur;
        }
      "
    }

    // 45° wipe, hard edge, ~0.8s — matches the awww wallpaper wipe duration.
    NumberAnimation {
      id: wipeAnim
      target: wipeOverlay
      property: "progress"
      from: 0.0
      to: 1.0
      duration: 800
      easing.type: Easing.Linear
      onRunningChanged: {
        if (!running) {
          // Commit the new theme as the base and hide the wipe machinery.
          root.barBg = root.pendingBg;
          root.barAccent = root.pendingAccent;
          pendingLayer.visible = false;
          wipeOverlay.visible = false;
          wipeOverlay.progress = 0.0;
        }
      }
    }
  }
}
