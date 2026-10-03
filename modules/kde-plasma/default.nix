{
  pkgs,
  config,
  ...
}: {
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma6.enable = true;

  services.xserver.enable = true;

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };
}
