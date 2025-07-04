{config, pkgs, inputs, ... }:
{

imports = [
    ./apps/home-manager.nix
];

environment.systemPackages = with pkgs; [
    # DE / WM
    inputs.niri-flake.nixosModules.niri
    inputs.stylix.nixosModules.stylix
    ./apps/sddm.nix
    ./apps/niri.nix
    ./modules/apps/stylix.nix
];

}
