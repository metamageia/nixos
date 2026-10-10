{
  config,
  pkgs,
  lib,
  userValues,
  ...
}: let
  cfg = config.theming.wallust;

  wallpaperDirs = [userValues.wallpapersDir];

  hermesSkinsDir = "/var/lib/hermes/.hermes/skins";

  zenProfileDir = "e06yfgug.Default Profile";

  wallustCfgDir = "${config.xdg.configHome}/wallust";

  tomlFormat = pkgs.formats.toml {};

  hermes-skins-dir = pkgs.writeShellScriptBin "hermes-skins-dir" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    explicit="${hermesSkinsDir}"
    if [ -n "$explicit" ]; then echo "$explicit"; exit 0; fi
    pid=$("${pkgs.procps}/bin/pgrep" -f 'share/hermes-desktop' | "${pkgs.coreutils}/bin/head" -n1 || true)
    if [ -n "$pid" ]; then
      home=$("${pkgs.coreutils}/bin/tr" '\0' '\n' < "/proc/$pid/environ" 2>/dev/null \
        | "${pkgs.gnugrep}/bin/grep" '^HERMES_HOME=' | "${pkgs.coreutils}/bin/cut" -d= -f2- || true)
      if [ -n "''${home:-}" ]; then echo "$home/skins"; exit 0; fi
    fi
    if [ -n "''${HERMES_HOME:-}" ]; then echo "$HERMES_HOME/skins"; exit 0; fi
    if [ -d /var/lib/hermes/.hermes/skins ]; then echo /var/lib/hermes/.hermes/skins; exit 0; fi
    echo "$HOME/.hermes/skins"
  '';

  wallust-apply = pkgs.writeShellScriptBin "wallust-apply" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    wp="$1"
    CONFIG_DIR="${wallustCfgDir}"

    [ -n "$wp" ] || exit 0
    [ -f "$wp" ] || { echo "wallust-apply: not a file: $wp" >&2; exit 1; }

    mkdir -p "${config.xdg.configHome}/zen/${zenProfileDir}/chrome"
    mkdir -p "/home/metamageia/Sync/Obsidian/.obsidian/snippets"

    ${pkgs.wallust}/bin/wallust run --config-dir "$CONFIG_DIR" "$wp"

    skins_dir="$(${hermes-skins-dir}/bin/hermes-skins-dir)"
    mkdir -p "$skins_dir"
    base="$(basename "$wp")"
    skin_name="$(echo "''${base%.*}" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')"
    skin_name="''${skin_name:-wallust}"
    sed "s/^name:.*/name: $skin_name/" "$CONFIG_DIR/hermes-skin.yaml" > "$skins_dir/wallust.yaml"

    export WAYLAND_DISPLAY="wayland-1"
    ${pkgs.awww}/bin/awww img "$wp" --transition-type wipe --transition-angle 45 --transition-duration 0.8

    echo "$wp" > "${wallustCfgDir}/last-wallpaper"

    ${pkgs.libnotify}/bin/notify-send "wallust" "Themed from $(basename "$wp")" 2>/dev/null || true
  '';

  wallust-switch = pkgs.writeShellScriptBin "wallust-switch" ''
    set -euo pipefail

    list_wallpapers() {
      for d in ${lib.concatStringsSep " " (map (d: "\"${d}\"") wallpaperDirs)}; do
        [ -d "$d" ] || continue
        ${pkgs.findutils}/bin/find "$d" -maxdepth 1 -type f \
          \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print
      done | ${pkgs.coreutils}/bin/sort -t/ -k2
    }

    choice="$(list_wallpapers | ${pkgs.gnugrep}/bin/grep -o '[^/]*$' | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt 'Wallpaper: ')"
    [ -n "$choice" ] || exit 0

    wp="$(list_wallpapers | ${pkgs.gnugrep}/bin/grep -F "/''${choice}" | head -n1)"
    [ -n "$wp" ] || { echo "wallust-switch: not found: $choice" >&2; exit 1; }
    exec ${wallust-apply}/bin/wallust-apply "$wp"
  '';
in {
  options.theming.wallust.templates = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        source = lib.mkOption {
          type = lib.types.path;
          description = "Wallust template file.";
        };
        target = lib.mkOption {
          type = lib.types.str;
          description = "Absolute path wallust renders the template to.";
        };
      };
    });
    default = {};
    description = "Wallust templates registered by per-app modules.";
  };

  config = {
    home.packages = with pkgs; [
      wallust
      libnotify
      wallust-apply
      wallust-switch
      hermes-skins-dir
    ];

    home.file =
      {
        ".config/wallust/wallust.toml".source = tomlFormat.generate "wallust.toml" {
          templates =
            lib.mapAttrs (name: t: {
              template = "${name}.tmpl";
              inherit (t) target;
            })
            cfg.templates;
        };
      }
      // lib.mapAttrs' (
        name: t:
          lib.nameValuePair ".config/wallust/templates/${name}.tmpl" {inherit (t) source;}
      )
      cfg.templates;
  };
}
