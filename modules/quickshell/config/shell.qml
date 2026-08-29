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

  // The palette type is `Colors` (capital, from Colors.qml). Its instance id is
  // `colors` — a ShellRoot child, so like `niri` below it is reachable by bare
  // name (`colors.<x>`) from every component in this config, including the Bar
  // widgets in modules/bar/ (confirmed pattern: reference quickshell-niri's Bar
  // accesses `niri.focusedWindow` the same way). Earlier failures came from the
  // type being lowercase `colors` colliding with the id.
  Colors { id: colors }

  // Watch the wallust-generated palette file and re-apply colours on change.
  // Lives here (not inside Colors.qml) because ShellRoot holds child objects
  // cleanly; Colors.qml stays pure data. `onLoaded`/`onFileChanged` fire when
  // wallust rewrites the file (Mod+W), triggering the crossfade Behaviours.
  FileView {
    id: paletteFile
    path: colors.palettePath
    watchChanges: true
    onFileChanged: this.reload()
    onLoaded: {
      var text = this.text()
      try { colors.applyPalette(JSON.parse(text)) }
      catch (e) { /* corrupt/unparseable — keep current colours */ }
    }
  }

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
