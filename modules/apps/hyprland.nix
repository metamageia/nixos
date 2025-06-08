{ pkgs, ... }:
{

services.xserver.displayManager.sddm.enable = true;
services.displayManager.sddm.wayland.enable = true;

services.hyprland = {
  enable = true;
};

environment.sessionVariables.NIXOS_OZONE_WL = "1"; #Fixes electron apps in wayland

xdg.portal = {
  enable = true;
  extraPortals = [xdg-portal-gtk];
};

environment.systemPackages = with pkgs; [
  waybar
  dunst
  libnotify
  hyprpaper
  kitty
  gtk3
  rofi-wayland
];

}
