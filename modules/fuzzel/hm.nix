{ config, pkgs, inputs, ... }:
{
    programs.fuzzel.enable =true;
    stylix.targets.fuzzel.enable = true; 
    home.packages = with pkgs; [
        fuzzel
    ];

    programs.fuzzel.settings = {
        main = {
        font      = "DejaVu Sans:size=16";
        dpi-aware = "no";
        };
    };

}