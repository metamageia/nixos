{pkgs, config, ...}:
{

services.xserver.displayManager.sddm.enable = true;
services.displayManager.sddm.wayland.enable = true;
programs.niri.enable = true;

environment.sessionVariables.NIXOS_OZONE_WL = "1";

}
