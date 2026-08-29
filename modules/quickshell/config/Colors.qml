import QtQuick
import Quickshell
import Quickshell.Io

// Centralised palette for the bar, wired to wallust (Phase 2b).
//
// wallust renders a small JSON palette
// (~/.config/quickshell/wallust-palette.json) from the active wallpaper — see
// modules/wallust default.nix -> [templates].quickshell. This object watches that
// file (FileView.watchChanges) and re-applies the colours whenever wallust rewrites
// it. Every Behaviour below crossfades the change over ~400ms, so a re-theme
// (Mod+W / wallust-switch) makes the bar colours MORPH smoothly instead of snapping
// — the whole payoff over GTK waybar.
//
// Because all widgets bind `color: colors.<x>`, animating the source property here
// propagates the tween to every consumer with zero per-widget edits.

QtObject {
  id: root

  // Path to the wallust-generated palette. Set explicitly by the launcher
  // (quickshell-bar wrapper -> QUICKSHELL_WALLUST_PALETTE) so the bar and wallust
  // always agree on one path; falls back to the standard config location.
  readonly property string palettePath: Quickshell.env("QUICKSHELL_WALLUST_PALETTE") ||
    ((Quickshell.env("XDG_CONFIG_HOME") || "~/.config") + "/quickshell/wallust-palette.json")

  FileView {
    id: paletteFile
    path: root.palettePath
    watchChanges: true
    // No blockLoading: before wallust has run the file may not exist; we keep the
    // static defaults instead of blocking. wallust creating/rewriting the file
    // fires onLoaded/onFileChanged -> applyPalette.
    onFileChanged: this.reload()
    onLoaded: root.applyPalette()
  }

  // Static defaults mirror the repo's purple/gold waybar theme so the swap is
  // visually continuous before wallust has run (or if the palette is unreadable).
  property color bg: "#0d0d14"
  property color fg: "#e8e6f0"
  property color accent: "#7b68ab"
  property color gold: "#d4a017"
  property color muted: "#8b8bab"
  property color urgent: "#ff5555"
  property color green: "#5e7a5e"
  property color blue: "#6b8e9f"

  // Re-apply the wallust palette. A corrupt/missing file is ignored so the bar
  // keeps its last good colours instead of snapping back to the defaults.
  function applyPalette() {
    var j
    try { j = JSON.parse(paletteFile.text()) }
    catch (e) { return }
    if (!j) return
    if (typeof j.bg === "string") root.bg = j.bg
    if (typeof j.fg === "string") root.fg = j.fg
    if (typeof j.accent === "string") root.accent = j.accent
    if (typeof j.gold === "string") root.gold = j.gold
    if (typeof j.muted === "string") root.muted = j.muted
    if (typeof j.urgent === "string") root.urgent = j.urgent
    if (typeof j.green === "string") root.green = j.green
    if (typeof j.blue === "string") root.blue = j.blue
  }

  // Smooth crossfade on every palette colour. Centralised here = one place, and
  // the tween reaches every widget via its `colors.<x>` binding.
  Behavior on bg { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
  Behavior on fg { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
  Behavior on accent { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
  Behavior on gold { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
  Behavior on muted { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
  Behavior on urgent { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
  Behavior on green { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
  Behavior on blue { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
}
