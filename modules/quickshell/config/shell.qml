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

  // NOTE: the palette type is `colors` (lowercase) because the file is
  // colors.qml — QML derives the type name from the filename, case-sensitively.
  // `Colors` (capital) would fail with "Colors is not a type". The instance id
  // is `palette` (distinct from the type name) to avoid the QML id/type
  // collision; `property alias colors` exposes it under the name the widgets
  // reference (`colors.<x>`), resolved via dynamic scope.
  property alias colors: palette
  colors { id: palette }

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
