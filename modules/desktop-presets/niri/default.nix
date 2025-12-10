{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  imports = [
    ../../niri
    ../../niri/home.nix
    ../../sddm
    ../../swww
    ../../waybar
    ../../fuzzel
  ];
}
