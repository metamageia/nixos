{ config
, pkgs
, lib
, inputs
, userValues
, ...
}:
# QuickShell status bar for niri, replacing waybar (removed in Phase 3).
#
# QUICKSHELL IS PACKAGE-ONLY: there is no programs.quickshell NixOS/home-manager
# module in nixpkgs (verified pkgs.quickshell is a package only). The bar is pure
# QML launched by niri's `spawn-at-startup` (see desktop-presets/niri wiring).
#
# The bar's icons are monochrome SVGs tinted at runtime via
# Qt5Compat.GraphicalEffects.ColorOverlay (Phase 4c). That module is NOT in
# QuickShell's default QML import path, so the launcher wrapper below prepends
# qt5compat's qml dir to QML2_IMPORT_PATH. Without it, `import
# Qt5Compat.GraphicalEffects` fails to resolve and the bar won't start.
#
# qml-niri (imiric/qml-niri) is a Qt6 QML plugin exposing niri IPC to QuickShell.
# It is NOT in nixpkgs, so it's a flake input (qml-niri.url = github:imiric/qml-niri)
# and its QML plugin dir is appended to QML2_IMPORT_PATH so QuickShell can `import Niri`.
# The plugin installs to $out/lib/qt-6/qml/Niri/ (see qml-niri/default.nix:
# qmlOutPath = "$out/${qt6.qtbase.qtQmlPrefix}" => lib/qt-6/qml). We point
# QML2_IMPORT_PATH at that lib/qt-6/qml parent so `Niri` resolves.

let
  # The bar's QML lives in the Nix store (built from this module) and is copied to
  # ~/.config/quickshell/bar. We launch quickshell against that config dir via
  # `quickshell --config <name>` (the `quickshell -c` / `--config` flag takes a
  # config *name* under XDG config quickshell dirs, OR a path; we use the path form
  # --config $cfgDir to be unambiguous and store-independent).
  barSrc = ./config-minimal;

  # wallust-generated palette (JSON) the bar watches for live theme crossfades.
  # Must match modules/wallust default.nix [templates].quickshell target exactly.
  palettePath = "${config.xdg.configHome}/quickshell/wallust-palette.json";

  # Phase 6 — the diamond wallpaper picker. State file the Mod+W toggle script
  # flips open/closed; the bar watches it via FileView and show()/hide()s the
  # picker window. Git-tracked wallpapers dir (same source the wallust switcher
  # uses) so the picker can enumerate and thumbnail them at runtime.
  pickerStatePath = "${config.xdg.configHome}/quickshell/picker-state";
  wallpapersDir = userValues.wallpapersDir;

  # Phase 6 — toggles the picker open/closed by flipping picker-state. Mod+W
  # spawns this (replaces wallust-switch as the primary picker entry).
  wallpaper-picker-toggle = pkgs.writeShellScriptBin "wallpaper-picker-toggle" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    STATE="${pickerStatePath}"
    mkdir -p "$(dirname "$STATE")"
    if [ -f "$STATE" ] && [ "$(cat "$STATE")" = "open" ]; then
      echo closed > "$STATE"
    else
      echo open > "$STATE"
    fi
  '';

  # Wallust-ready palette. Phase 2b will animate these (ColorAnimation/Behavior);
  # for now they are static central bindings the QML reads via `Colors`. Keeping
  # them in ONE file (colors.qml) means Phase 2b only touches this file + adds
  # Behavior blocks — no widget edits needed.
  #
  # Defaults below match the repo's existing purple/gold waybar theme so the swap
  # is visually continuous. They are overridable later via stylix/wallust injection.
  barConfig = pkgs.stdenv.mkDerivation {
    pname = "quickshell-bar";
    version = "1.0.0";
    src = barSrc;
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

  # Build the launcher script. It sets QML2_IMPORT_PATH to include the qml-niri
  # plugin dir, then execs quickshell pointing at our store-baked config dir.
  # `--config` here is passed the absolute path to the config dir (quickshell
  # accepts a path to a directory containing shell.qml).
  qsWrapper = pkgs.writeShellScriptBin "quickshell-bar" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    # QML2_IMPORT_PATH may be unset at session start (not inherited); under
    # `set -u` the bare "$QML2_IMPORT_PATH" would abort with "unbound variable".
    # Guard it so the wrapper always launches.
    if [ -z "''${QML2_IMPORT_PATH:-}" ]; then
      export QML2_IMPORT_PATH="${inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.default}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml"
    else
      export QML2_IMPORT_PATH="${inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.default}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml:$QML2_IMPORT_PATH"
    fi
    export QUICKSHELL_WALLUST_PALETTE="${palettePath}"
    export QUICKSHELL_WALLPAPERS_DIR="${wallpapersDir}"
    exec ${pkgs.quickshell}/bin/quickshell --config "${barConfig}"
  '';
in
{
  # ---- packages: quickshell, the qml-niri plugin availability, audio/network tools ----
  # quickshell itself comes from nixpkgs; qml-niri plugin is pulled via the wrapper's
  # QML2_IMPORT_PATH (so it doesn't need to be a top-level package, but we add it to
  # the env so it's inspectable).
  home.packages = with pkgs; [
    quickshell
    qsWrapper
    wallpaper-picker-toggle
    inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ---- ship the bar QML into ~/.config/quickshell/bar so it's user-editable & live ----
  # (Phase 2b can patch these files at runtime without a rebuild, matching how
  #  wallust owns waybar/fuzzel/kitty files.)
  home.file.".config/quickshell/bar".source = barConfig;

  # Seed the picker state file to "closed" so the bar starts with the picker
  # hidden. MUST be a real writable file, NOT a home-manager store symlink —
  # home.file with `.text` creates a read-only /nix/store symlink, so the
  # wallpaper-picker-toggle script's `echo open >` would fail with "Read-only
  # file system" and the picker would never open (hit live 08-29). Create it via
  # an activation script so it's a plain writable file on disk.
  home.activation.createPickerState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/quickshell"
    echo "closed" > "$HOME/.config/quickshell/picker-state"
  '';
}
