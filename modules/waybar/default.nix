{ config, pkgs, inputs, ... }:
{

  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      margin = "5";
      position = "top";
      height = 30;

      modules-left = [ "network" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio""cpu" "memory" ];

      clock = {
        format = " {:%I:%M %p   %m/%d} ";
        tooltip-format = ''
          <big>{:%Y %B}</big>
          <tt><small>{calendar}</small></tt>'';
      };

    }];
    style = ''
    * {
      border-radius: 12;
      }
    '';
  };

  stylix.targets.waybar.enable = true; 

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "always";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

}