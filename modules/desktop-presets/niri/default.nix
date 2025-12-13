{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  imports = [
    ../../desktop-presets

    ../../niri
    ../../niri/home.nix
    ../../sddm
    ../../swww
    ../../waybar
    ../../fuzzel
  ];
}
