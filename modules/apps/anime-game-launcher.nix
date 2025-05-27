# Set up AAGL for HSR, Genshin, etc
{ config, pkgs, aagl, ... }:

{
 
  imports = [ aagl.nixosModules.default ];
  nix.settings = aagl.nixConfig; # Set up Cachix

  # programs.anime-game-launcher.enable = true;
  # programs.anime-games-launcher.enable = true;
  # programs.anime-borb-launcher.enable = true;
  programs.honkers-railway-launcher.enable = true;
  # programs.honkers-launcher.enable = true;
}
