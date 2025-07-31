{
  inputs,
  system,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/grub

    ../../modules/core-configuration.nix
    ../../modules/desktop.nix

    # Users
    ../../users/metamageia
    inputs.niri-flake.nixosModules.niri
    inputs.stylix.nixosModules.stylix

    # Special Modules
    ../../modules/musicproduction.nix
    ../../modules/development.nix
    inputs.homelab.nixosModules.homelab-node
    #../../modules/gaming.nix
  ];

  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${system}
  ];
}
