import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Niri
import "./modules/bar/"

// Entry point for the QuickShell bar.
//   - `colors` (colors.qml, sibling) centralises the palette so Phase 2b can add
//     ColorAnimation/Behavior without touching any widget.
//   - `niri` (qml-niri plugin, import Niri) is the niri IPC bridge.
// The bar is a single PanelWindow; niri is single-output-first but the pattern
// scales to Variants{ Quickshell.screens } later if multi-monitor is wanted.
ShellRoot {
  id: root

  Colors { id: colors }

  Niri {
    id: niri
    Component.onCompleted: connect()
    onConnected: console.info("quickshell: connected to niri")
    onErrorOccurred: function (error) {
      console.error("quickshell: niri connection error:", error)
    }
  }

  LazyLoader {
    active: true
    component: Bar {}
  }
}
