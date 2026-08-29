import QtQuick

// Centralised palette for the bar. Phase 2b will wire wallust/stylix colours in
// here and add ColorAnimation/Behavior blocks; no widget edits required then.
// Defaults mirror the repo's existing purple/gold waybar theme for a continuous swap.
QtObject {
  property color bg: "#0d0d14"
  property color fg: "#e8e6f0"
  property color accent: "#7b68ab"
  property color gold: "#d4a017"
  property color muted: "#8b8bab"
  property color urgent: "#ff5555"
  property color green: "#5e7a5e"
  property color blue: "#6b8e9f"
}
