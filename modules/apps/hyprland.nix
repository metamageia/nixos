{ pkgs, ... }:
{

services.xserver.displayManager.sddm.enable = true;
services.xserver.enable = true; #Needed for xwayland

programs.hyprland = {
  enable = true;
  xwayland.enable = true;
};

environment.sessionVariables.NIXOS_OZONE_WL = "1"; #Fixes electron apps in wayland

environment.systemPackages = with pkgs; [
  waybar
  hyprpaper
  rofi-wayland
  dunst
  libnotify
  kitty
];

}
