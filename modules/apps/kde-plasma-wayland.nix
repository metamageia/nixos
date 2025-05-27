{ pkgs, config, ... }:

{
  # Enable the X11 windowing system (required for SDDM even when using Wayland)
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable SDDM display manager with Wayland support
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Enable KDE Plasma 6 desktop environment
  services.desktopManager.plasma6.enable = true;

  # Set default session to Wayland
  services.displayManager.defaultSession = "plasma";

  # Enable Waydroid
  virtualisation.waydroid.enable = true;
}
