{config, pkgs, inputs, ... }:
{

imports = [
    ./apps/home-manager.nix
        # DE / WM
    ./apps/sddm.nix
    ./apps/niri.nix
    ./apps/stylix.nix

];

environment.systemPackages = with pkgs; [

];

}
