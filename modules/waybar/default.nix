{
  config,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        margin = "8";
        position = "top";
        height = 36;

        modules-left = ["custom/planetary-hour" "niri/workspaces"];
        modules-center = ["clock"];
        modules-right = ["pulseaudio" "cpu" "memory" "network" "tray"];

        clock = {
          format = "{:%I:%M %p  ·  %a %d %b}";
          interval = 60;
          tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
        };
        pulseaudio = {
          format = " {volume}%";
          format-muted = " muted";
        };
        cpu = {
          format = " {usage}%";
        };
        memory = {
          format = " {percentage}%";
        };
        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " connected";
          format-disconnected = " none";
        };
      }
    ];
    style = ''
      * {
        font-family: "Inter", "EB Garamond", sans-serif;
        font-size: 13px;
      }
      window#waybar {
        background: alpha(#0d0d14, 0.85);
        border: 1px solid alpha(#7b68ab, 0.3);
        border-radius: 12px;
      }
      #workspaces button {
        color: #8b8bab;
        padding: 0 8px;
        margin: 4px 2px;
      }
      #workspaces button.active {
        color: #d4a017;
        background: alpha(#7b68ab, 0.2);
        border: 1px solid #d4a017;
        border-radius: 6px;
      }
      #clock {
        color: #c9a227;
        font-weight: bold;
        padding: 0 16px;
        margin: 4px 2px;
        background: alpha(#1a1a2e, 0.5);
        border-radius: 6px;
      }
      #pulseaudio {
        color: #6b8e9f;
      }
      #cpu {
        color: #8b2252;
      }
      #memory {
        color: #5e7a5e;
      }
      #network {
        color: #7b68ab;
      }
      #custom-planetary-hour {
        color: #d4a017;
        font-weight: bold;
        padding: 0 12px;
        margin: 4px 2px;
        background: alpha(#1a1a2e, 0.5);
        border-radius: 6px;
        border: 1px solid alpha(#d4a017, 0.3);
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
}
