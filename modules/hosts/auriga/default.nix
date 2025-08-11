{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../grub

    ../core-configuration.nix
    ../desktop.nix

    # Users
    ../users/metamageia
    inputs.niri-flake.nixosModules.niri
    inputs.stylix.nixosModules.stylix

    # Special Modules
    #../musicproduction.nix
    #../development.nix
    #../gaming.nix
    ../homelab
  ];

  environment.systemPackages = with pkgs; [
    # inputs.alejandra.defaultPackage.${system}
    k3s
  ];
}
