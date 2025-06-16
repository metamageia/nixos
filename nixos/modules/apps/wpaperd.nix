{ config, pkgs, inputs, wallpaper, ... }:
{
  services.wpaperd = {
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