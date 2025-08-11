{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./home-manager
    # DE / WM
    ./sddm
    ./niri
    ./stylix

    ./musicproduction.nix
    ./development.nix
    ./gaming.nix
  ];
}
