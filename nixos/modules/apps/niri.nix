{ pkgs, config, inputs,... }:
{
  
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    qt5.qtwayland
    brightnessctl
    wev
    kdePackages.dolphin
    inputs.zen-browser.packages."${system}".generic
  ];


  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    config.common = {
      default = [ "wlr" ];
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };
}
