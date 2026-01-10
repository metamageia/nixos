{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  # This is a home-manager module
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = lib.mkForce "DejaVu Sans:size=16";
        dpi-aware = "no";
      };
    };
  };

  home.packages = with pkgs; [
    jq
    wl-clipboard
    xdg-utils
    coreutils
  ];
}
