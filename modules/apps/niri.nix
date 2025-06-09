{ pkgs, config, ... }:
{
  services.xserver.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    brightnessctl
    waybar
    wev

  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };
}
