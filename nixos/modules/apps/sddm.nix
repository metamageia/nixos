{ pkgs, config, wallpaper, ... }:
{
 services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    settings = {
      General = {
        Background = "wallpaper";
      };
    };
  };
}
