{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  programs.fuzzel.enable = true;

  system.packages = with pkgs; [
    fuzzel
    jq
    wl-clipboard
    xdg-utils
    coreutils
  ];

  programs.fuzzel.settings = {
    main = {
      font = lib.mkForce "DejaVu Sans:size=16";
      dpi-aware = "no";
    };
  };
}
