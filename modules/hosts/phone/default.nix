{pkgs, ...}: {
  imports = [
    ../../comin
  ];
  environment.packages = with pkgs; [
    git
  ];
  system.stateVersion = "24.05";
}
