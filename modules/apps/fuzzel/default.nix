{ config, pkgs, inputs, ... }:
{
    programs.fuzzel.enable =true;
    stylix.targets.fuzzel.enable = true; 
    home.packages = with pkgs; [
        fuzzel
    ];

}