{ config
, pkgs
, lib
, inputs
, ...
}:
# QuickShell status bar for niri, replacing waybar (removed in Phase 3).
#
# QUICKSHELL IS PACKAGE-ONLY: there is no programs.quickshell NixOS/home-manager
# module in nixpkgs (verified pkgs.quickshell is a package only). The bar is pure
# QML launched by niri's `spawn-at-startup` (see desktop-presets/niri wiring).
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
  barSrc = ./config;

  # wallust-generated palette (JSON) the bar watches for live theme crossfades.
  # Must match modules/wallust default.nix [templates].quickshell target exactly.
  palettePath = "${config.xdg.configHome}/quickshell/wallust-palette.json";

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
    export QML2_IMPORT_PATH="${inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.default}/lib/qt-6/qml:$QML2_IMPORT_PATH"
    export QUICKSHELL_WALLUST_PALETTE="${palettePath}"
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
    inputs.qml-niri.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ---- ship the bar QML into ~/.config/quickshell/bar so it's user-editable & live ----
  # (Phase 2b can patch these files at runtime without a rebuild, matching how
  #  wallust owns waybar/fuzzel/alacritty files.)
  home.file.".config/quickshell/bar".source = barConfig;
}
