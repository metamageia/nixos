{pkgs, ...}: {
  home.packages = with pkgs; [
    alacritty
  ];
  stylix.targets.alacritty.enable = true;
}
