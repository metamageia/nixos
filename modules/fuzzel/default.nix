{ config, pkgs, lib, inputs, ... }:
{
    programs.fuzzel.enable =true;
    stylix.targets.fuzzel.enable = true; 
    home.packages = with pkgs; [
        fuzzel
    ];

    stylix.targets.fuzzel.enable = true; 

    programs.fuzzel.settings = {
        main = {
        font      =  lib.mkForce "DejaVu Sans:size=16";
        dpi-aware = "no";
        };
    };

}