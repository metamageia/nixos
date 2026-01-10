{
  config,
  pkgs,
  lib,
  inputs,
  userValues,
  ...
}: let
  fuzzel-search = pkgs.writeShellScriptBin "fuzzel-search" (builtins.readFile ../../fuzzel/fuzzel-search.sh);
in {
  imports = [
    ../../desktop-presets

    ../../niri
    ../../sddm
  ];

  home-manager.sharedModules = [
    ({config, ...}: {
      # Niri window manager settings
      programs.niri = {
        settings = {
          environment = {
            DISPLAY = ":0";
          };
          spawn-at-startup = [
            {command = ["xwayland-satellite"];}
          ];
          window-rules = [
            # Geometry Rules
            {
              matches = [{}];
              draw-border-with-background = false;
              clip-to-geometry = true;
              geometry-corner-radius = {
                top-left = 12.0;
                top-right = 12.0;
                bottom-right = 12.0;
                bottom-left = 12.0;
              };
            }
            # Opacity Rules
            {
              matches = [{}];
              excludes = [{app-id = "zen";}];
              opacity = 0.95;
            }
          ];
          binds = with config.lib.niri.actions; {
            # Niri
            "Mod+Shift+E".action = quit;
            "Mod+Shift+Slash".action = show-hotkey-overlay;

            # Hotkeys
            "Mod+D".action.spawn = "fuzzel";
            "Mod+S".action.spawn = ["${fuzzel-search}/bin/fuzzel-search"];
            "Mod+T".action.spawn = "alacritty";
            "Mod+P".action.screenshot = {};

            # Audio
            "XF86AudioRaiseVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
            "XF86AudioLowerVolume".action.spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];

            # Windows and Workspaces
            "Mod+Q".action = close-window;

            "Mod+Left".action = focus-column-left;
            "Mod+Down".action = focus-window-down;
            "Mod+Up".action = focus-window-up;
            "Mod+Right".action = focus-column-right;

            "Mod+H".action = focus-column-left;
            "Mod+J".action = focus-window-down;
            "Mod+K".action = focus-window-up;
            "Mod+L".action = focus-column-right;

            "Mod+Ctrl+Left".action = move-column-left;
            "Mod+Ctrl+Down".action = move-window-down;
            "Mod+Ctrl+Up".action = move-window-up;
            "Mod+Ctrl+Right".action = move-column-right;
            "Mod+Ctrl+H".action = move-column-left;
            "Mod+Ctrl+J".action = move-window-down;
            "Mod+Ctrl+K".action = move-window-up;
            "Mod+Ctrl+L".action = move-column-right;

            "Mod+Home".action = focus-column-first;
            "Mod+End".action = focus-column-last;
            "Mod+Ctrl+Home".action = move-column-to-first;
            "Mod+Ctrl+End".action = move-column-to-last;

            "Mod+Shift+Left".action = focus-monitor-left;
            "Mod+Shift+Down".action = focus-monitor-down;
            "Mod+Shift+Up".action = focus-monitor-up;
            "Mod+Shift+Right".action = focus-monitor-right;
            "Mod+Shift+H".action = focus-monitor-left;
            "Mod+Shift+J".action = focus-monitor-down;
            "Mod+Shift+K".action = focus-monitor-up;
            "Mod+Shift+L".action = focus-monitor-right;

            "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
            "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
            "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
            "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
            "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
            "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
            "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
            "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

            "Mod+Page_Down".action = focus-workspace-down;
            "Mod+Page_Up".action = focus-workspace-up;
            "Mod+U".action = focus-workspace-down;
            "Mod+I".action = focus-workspace-up;

            "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
            "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
            "Mod+Ctrl+U".action = move-column-to-workspace-down;
            "Mod+Ctrl+I".action = move-column-to-workspace-up;

            "Mod+Shift+Page_Down".action = move-workspace-down;
            "Mod+Shift+Page_Up".action = move-workspace-up;
            "Mod+Shift+U".action = move-workspace-down;
            "Mod+Shift+I".action = move-workspace-up;

            "Mod+1".action = focus-workspace 1;
            "Mod+2".action = focus-workspace 2;
            "Mod+3".action = focus-workspace 3;
            "Mod+4".action = focus-workspace 4;
            "Mod+5".action = focus-workspace 5;
            "Mod+6".action = focus-workspace 6;
            "Mod+7".action = focus-workspace 7;
            "Mod+8".action = focus-workspace 8;
            "Mod+9".action = focus-workspace 9;

            "Mod+BracketLeft".action = consume-or-expel-window-left;
            "Mod+BracketRight".action = consume-or-expel-window-right;
            "Mod+Comma".action = consume-window-into-column;
            "Mod+Period".action = expel-window-from-column;

            "Mod+R".action = switch-preset-column-width;
            "Mod+Shift+R".action = switch-preset-window-height;
            "Mod+Ctrl+R".action = reset-window-height;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+Ctrl+F".action = expand-column-to-available-width;
            "Mod+C".action = center-column;
          };
        };
      };

      # Fuzzel launcher
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            font = lib.mkForce "DejaVu Sans:size=16";
            dpi-aware = "no";
          };
        };
      };

      home.packages = with pkgs; [
        fuzzel-search
        swww
        jq
        wl-clipboard
        xdg-utils
        coreutils
      ];

      # swww wallpaper daemon
      systemd.user.services.swww = {
        Unit = {
          Description = "Start swww daemon";
          After = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.swww}/bin/swww-daemon --format xrgb";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };

      systemd.user.services.swww-wallpaper = {
        Unit = {
          Description = "Set initial wallpaper using swww";
          After = ["swww.service"];
          Wants = ["swww.service"];
        };
        Service = {
          ExecStart = "${pkgs.swww}/bin/swww img '${userValues.wallpaper}' --transition-type center";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };

      # Waybar status bar
      programs.waybar = {
        enable = true;
        settings = [
          {
            layer = "top";
            margin = "5";
            position = "top";
            height = 30;

            modules-left = ["network"];
            modules-center = ["clock"];
            modules-right = ["pulseaudio" "cpu" "memory"];

            clock = {
              format = " {:%I:%M %p   %m/%d} ";
              tooltip-format = ''
                <big>{:%Y %B}</big>
                <tt><small>{calendar}</small></tt>'';
            };
          }
        ];
        style = ''
          * {
            border-radius: 12;
            }
        '';
      };

      systemd.user.services.waybar = {
        Unit = {
          Description = "Waybar status bar";
          After = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.waybar}/bin/waybar";
          Restart = "always";
          RestartSec = 2;
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    })
  ];
}
