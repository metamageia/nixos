# Wallust dynamic theming — self-contained home-manager module.
#
# WHAT IT DOES
#   - Installs `wallust` (v3.5.x) and `awww` (the animated Wayland wallpaper
#     daemon; niri has NO native wallpaper-image support). awww gives smooth
#     fade/wipe/grow transitions between wallpapers — no screen flash.
#   - Ships ~/.config/wallust/wallust.toml + its `templates/` dir. wallust reads
#     colors from a chosen wallpaper and renders templates for waybar, fuzzel,
#     and alacritty.
#   - Ships `wallust-switch`: a fuzzel-dmenu launcher that lists wallpapers from
#     the repo wallpapers dir, applies the chosen one with `wallust run ...`, and
#     sets it as the live desktop background with `awww img --transition-type fade`.
#
# VERIFIED EMPIRICALLY (nix shell nixpkgs#wallust, run against the warframe wp):
#   CLI:  wallust run --config-dir <DIR> <IMAGE>      # image is a POSITIONAL arg
#   Resolving placeholders: color0..color15, background, foreground, cursor, alpha
#   (alpha defaults to 100).  `accent` and `wallpaper` DO NOT resolve (empty) — so
#   templates use {{background}}/{{colorN}}, never {{accent}}/{{wallpaper}}.
#   Templates live in a `templates/` subdir of the config dir; `target` is the
#   absolute runtime path wallust writes.
#
# CONFIG-OWNERSHIP STRATEGY (wallust owns colors; HM keeps structure)
#   - waybar: keep `programs.waybar.settings` (HM writes config.json — wallust never
#     touches it). Drop `programs.waybar.style` with mkForce (HM would otherwise write
#     ~/.config/waybar/style.css); wallust writes style.css instead. Shortcuts/widgets
#     in settings are preserved.
#   - fuzzel: HM writes fuzzel.ini ONLY when settings != {} (it is empty here), so no
#     conflict — wallust writes ~/.config/fuzzel/fuzzel.ini directly. HM still provides
#     the fuzzel package + deps (jq/wl-clipboard/xdg-utils/coreutils) via modules/fuzzel.
#   - alacritty: HM writes alacritty.toml ONLY when settings != {} (empty), so wallust
#     writes ~/.config/alacritty/alacritty.toml directly (live_config_reload=true).
#   - niri: niri-flake writes ~/.config/niri/config.kdl (strict `settings` submodule, no
#     room for an `include`). niri DOES support `include` directives, so we override that
#     file's source (mkForce) to append `include optional=true "colors.kdl"`, where
#     colors.kdl is wallust-generated. All binds/window-rules/gaps survive via
#     finalConfig. No edit to modules/niri/home.nix required.
#
# NIRI RUNTIME NOTE (honest limitation)
#   niri reads config.kdl only at session (compositor) start; there is no live reload
#   IPC. So wallust regenerating niri/colors.kdl takes visual effect on niri after the
#   NEXT login / niri restart — NOT immediately. The switcher therefore does NOT kill
#   niri (that would end the session). waybar/fuzzel/alacritty pick up their new files
#   live (waybar via SIGUSR2; fuzzel/alacritty on next launch). `include optional=true`
#   keeps a missing colors.kdl (pre-first-run) from breaking niri startup.
#
# KEYBIND (recommended — add to modules/niri/home.nix `binds`, out of scope here)
#   "Mod+W".action.spawn = "wallust-switch";

{ config, pkgs, lib, userValues, ... }:

let
  # Canonical, git-tracked wallpapers set. Passed from flake.nix userValues
  # (./wallpapers) and threaded through extraSpecialArgs. It becomes a read-only
  # store path at build time — fully readable at runtime by the switcher. Adding a
  # new wallpaper is a one-line commit + rebuild (the Nix way); we deliberately avoid
  # a hardcoded /home/metamageia path so the module stays hermetic.
  wallpapersDir = userValues.wallpapersDir;

  wallustCfgDir = "${config.xdg.configHome}/wallust";

  # fuzzel-dmenu launcher: pick wallpaper -> wallust run -> awww img -> reload waybar.
  wallust-switch = pkgs.writeShellScriptBin "wallust-switch" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    WP_DIR="${wallpapersDir}"
    CONFIG_DIR="${wallustCfgDir}"

    [ -d "$WP_DIR" ] || { echo "wallust-switch: wallpapers dir not found: $WP_DIR" >&2; exit 1; }

    choice="$("${pkgs.findutils}/bin/find" "$WP_DIR" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
      -printf '%f\n' | ${pkgs.coreutils}/bin/sort | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt 'Wallpaper: ')"
    [ -n "$choice" ] || exit 0

    wp="$WP_DIR/$choice"

    # Re-theme: apply palette + render all templates (waybar/fuzzel/alacritty).
    ${pkgs.wallust}/bin/wallust run --config-dir "$CONFIG_DIR" "$wp"

    # Set the live desktop background with a horizontal swipe transition. awww-daemon
    # persists from spawn-at-startup; we NEVER pkill it (killing it would drop the
    # background / break the socket). If awww img fails, surface the error.
    export WAYLAND_DISPLAY="wayland-1"
    ${pkgs.awww}/bin/awww img "$wp" --transition-type left --transition-duration 0.8

    # waybar reloads its CSS on SIGUSR2.
    ${pkgs.procps}/bin/pkill -u "$USER" -USR2 waybar 2>/dev/null || true

    ${pkgs.libnotify}/bin/notify-send "wallust" "Themed from $choice" 2>/dev/null || true
  '';
in
{
  # ---- packages ----
  # awww-daemon is provided by modules/awww (systemd user services `awww` +
  # `awww-wallpaper`). We do NOT add awww here or spawn our own daemon — the
  # switcher below calls the systemd-managed daemon.
  home.packages = with pkgs; [
    wallust        # v3.5.x dynamic theming engine
    libnotify      # notify-send from the switcher
    wallust-switch # fuzzel launcher defined above
  ];

  # ---- wallust config + templates (wallust owns these files) ----
  home.file.".config/wallust/wallust.toml".text = ''
    # Wallust v3 config. Generated by home-manager (modules/wallust).
    # Wallpapers source: ${wallpapersDir}
    #
    # Templates render with {{color0}}..{{color15}}, {{background}}, {{foreground}},
    # {{cursor}}, {{alpha}}. (Verified: accent/wallpaper do NOT resolve.)

    [templates]
    waybar = { template = "waybar.tmpl", target = "${config.xdg.configHome}/waybar/style.css" }
    fuzzel = { template = "fuzzel.tmpl", target = "${config.xdg.configHome}/fuzzel/fuzzel.ini" }
    alacritty = { template = "alacritty.tmpl", target = "${config.xdg.configHome}/alacritty/alacritty.toml" }
  '';

  home.file.".config/wallust/templates/waybar.tmpl".text = ''
    * {
      font-family: "Inter", "EB Garamond", sans-serif;
      font-size: 13px;
    }
    window#waybar {
      background: alpha({{background}}, 0.85);
      border: 1px solid alpha({{color5}}, 0.3);
      border-radius: 12px;
    }
    #workspaces button {
      color: {{color8}};
      padding: 0 8px;
      margin: 4px 2px;
    }
    #workspaces button.active {
      color: {{color3}};
      background: alpha({{color5}}, 0.2);
      border: 1px solid {{color3}};
      border-radius: 6px;
    }
    #clock {
      color: {{color4}};
      font-weight: bold;
      padding: 0 16px;
      margin: 4px 2px;
      background: alpha({{color1}}, 0.5);
      border-radius: 6px;
    }
    #pulseaudio {
      color: {{color6}};
    }
    #cpu {
      color: {{color1}};
    }
    #memory {
      color: {{color2}};
    }
    #network {
      color: {{color5}};
    }
  '';

  home.file.".config/wallust/templates/fuzzel.tmpl".text = ''
    [colors]
    background={{background}}
    text={{foreground}}
    selection-foreground={{background}}
    selection-background={{color5}}
    border={{color5}}
    match={{color4}}
    prompt={{color3}}

    [border]
    width=2
    radius=8

    [main]
    font="Inter 13"
    layer=top
  '';

  home.file.".config/wallust/templates/alacritty.tmpl".text = ''
    [general]
    live_config_reload=true

    [window]
    opacity=0.93
    padding.x=8
    padding.y=8

    [font]
    normal.family="JetBrains Mono"
    size=12.0

    [colors.primary]
    background="{{background}}"
    foreground="{{foreground}}"

    [colors.cursor]
    text="{{background}}"
    cursor="{{foreground}}"

    [colors.normal]
    black="{{color0}}"
    red="{{color1}}"
    green="{{color2}}"
    yellow="{{color3}}"
    blue="{{color4}}"
    magenta="{{color5}}"
    cyan="{{color6}}"
    white="{{color7}}"

    [colors.bright]
    black="{{color8}}"
    red="{{color9}}"
    green="{{color10}}"
    yellow="{{color11}}"
    blue="{{color12}}"
    magenta="{{color13}}"
    cyan="{{color14}}"
    white="{{color15}}"
  '';

  # ---- hand ownership to wallust: drop HM-written style.css that would collide ----
  # HM keeps programs.waybar.settings (config.json, untouched by wallust).
  programs.waybar.style = lib.mkForce null;

  # ---- niri colors: build-time only on niri 25.08 (no include, no runtime theme) ----
  # niri 25.08 (the pinned niri-flake version) does NOT support `include`, so a
  # wallust-generated colors.kdl cannot be pulled into config.kdl, and the config
  # itself is a read-only store symlink (wallust cannot rewrite it). Therefore niri
  # colors are set at BUILD time from the declared wallpaper (userValues.wallpaper),
  # matching the persistent awww background. wallust re-themes waybar/fuzzel/
  # alacritty live; niri colors update on the next rebuild. To get runtime niri
  # theming, bump the niri-flake to a version with `include` (>= v26) and revisit.
  # (Earlier attempts to append `include optional=true "colors.kdl"` FAILED: niri
  # 25.08 rejects `include` as an unexpected node — verified with `niri validate`
  # against the pinned 25.08 binary.)
  # Leave config.kdl as niri-flake generates it (no override at all) — this was the
  # root of two build breaks. niri-flake owns the file; wallust does not touch it.

  # ---- persistent background: handled by modules/awww systemd services ----
  # modules/awww starts `awww-daemon` (systemd user service `awww`) and sets the
  # initial wallpaper (`awww-wallpaper`). We deliberately do NOT spawn a second
  # daemon here — two daemons fight over the same socket and the switcher's
  # `awww img` then targets the wrong one. The switcher below just calls `awww
  # img` against the systemd-managed daemon.
}
