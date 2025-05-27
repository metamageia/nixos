{pkgs, config, ...}:
{

  # Enable qtile
    services.xserver.windowManager.qtile.enable = true;

  enviornment.systemPackages = with pkgs; [
    xorg.xrandr
    arandr
    libsForQt5.konsole
  ]

}
