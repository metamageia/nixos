{ config, pkgs, inputs, ... }:
{

  home.packages = with pkgs; [
    inputs.zen-browser.packages."${system}".default
  ];

    stylix.targets.zen-browser.enable = true; 

}