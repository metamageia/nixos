{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    lightdm
  ];
  services.displayManager.lightdm = {
    enable = true;
    wayland.enable = true;
  };
  stylix.targets.lightdm.enable = true;
}
