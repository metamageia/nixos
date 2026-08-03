{
  config,
  pkgs,
  lib,
  inputs,
  userValues,
  ...
}: {
  imports = [
    ../../desktop-presets

    ../../niri
    ../../sddm
  ];

  # Home-manager layer of the desktop: niri settings, waybar, fuzzel.
  # Imported here so the preset composes the whole desktop; hosts switch
  # desktops by swapping presets, not by touching user config.
  home-manager.sharedModules = [
    ../../niri/home.nix
    ../../waybar
    ../../fuzzel
  ];
}
