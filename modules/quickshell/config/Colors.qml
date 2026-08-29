import QtQuick

// Centralised palette for the bar. Pure DATA (no child objects): a plain QtObject
// exposing the colour properties the bar's widgets bind to (`colors.<x>`), plus a
// crossfade Behaviour on each so a wallust re-theme morphs instead of snapping.
// The FileView that watches the wallust palette file lives in shell.qml (a proper
// ShellRoot that holds child objects cleanly) and calls applyPalette() here.
QtObject {
  id: root

  // Path to the wallust-generated palette. Set by the launcher (quickshell-bar
  // wrapper -> QUICKSHELL_WALLUST_PALETTE); falls back to the standard config
  // location. The FileView in shell.qml reads this.
  readonly property string palettePath: Quickshell.env("QUICKSHELL_WALLUST_PALETTE") ||
    ((Quickshell.env("XDG_CONFIG_HOME") || "~/.config") + "/quickshell/wallust-palette.json")

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

  // Apply a palette object (from the JSON file read in shell.qml). A corrupt or
  // missing value is ignored so the bar keeps its last good colours.
  function applyPalette(paletteObj) {
    if (!paletteObj) return
    if (typeof paletteObj.bg === "string") root.bg = paletteObj.bg
    if (typeof paletteObj.fg === "string") root.fg = paletteObj.fg
    if (typeof paletteObj.accent === "string") root.accent = paletteObj.accent
    if (typeof paletteObj.gold === "string") root.gold = paletteObj.gold
    if (typeof paletteObj.muted === "string") root.muted = paletteObj.muted
    if (typeof paletteObj.urgent === "string") root.urgent = paletteObj.urgent
    if (typeof paletteObj.green === "string") root.green = paletteObj.green
    if (typeof paletteObj.blue === "string") root.blue = paletteObj.blue
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
