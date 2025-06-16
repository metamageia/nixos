{ config, pkgs, inputs, ... }:
{
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