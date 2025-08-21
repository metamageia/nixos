{pkgs, ...}: {
  environment.packages = [pkgs.vim];
  system.stateVersion = "24.05";
}
