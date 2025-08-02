{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    lightdm
  ];
  services.xserver = {
    enable = true;
    displayManager = {
      lightdm.enable = true;
      lightdm.greeters.gtk.enable = true;
    };
  };

  stylix.targets.lightdm.enable = true;
}
