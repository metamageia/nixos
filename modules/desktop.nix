{config, pkgs, inputs, ... }:
{

imports = [
    ./home-manager/default.nix
        # DE / WM
    ./sddm/default.nix
    ./niri/default.nix
    ./stylix/default.nix

];

environment.systemPackages = with pkgs; [
    iosevka
    font-awesome
    material-design-icons
];

}
