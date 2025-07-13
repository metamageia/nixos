{ config, pkgs, inputs, ... }:
{

  programs.waybar = {
    enable = true;
  };

  stylix.targets.waybar.enable = true; 

}