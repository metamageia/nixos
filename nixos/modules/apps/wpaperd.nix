{ config, pkgs, inputs, wallpaper, ... }:
{
  wpaperd = {
    enable = true;
    settings = {
      default = {
        path = wallpaper;
        mode = "center";
        # duration, sorting etc. ignored since path is a file
      };
    };
  };
}