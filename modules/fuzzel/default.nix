{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.fuzzel = {
    enable = true;
  };

  home.packages = with pkgs; [
    jq
    wl-clipboard
    xdg-utils
    coreutils
  ];
}
