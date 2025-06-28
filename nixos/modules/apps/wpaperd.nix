{ config, pkgs, inputs, wallpaper, ... }:
{
  wpaperd = {
    enable = true;
    settings = {
      default = {
        path = wallpaper;
        mode = "center";
      };
      DP-1 = {
        path = wallpaper;
        mode = "center";
      };
      DP-2 = {
        path = wallpaper;
        mode = "center";
      };
    };
  };
}