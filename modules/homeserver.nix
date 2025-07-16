{ config, pkgs, ... }:
{

imports = [
  #./apps/jellyfin.nix
  ./k3s/default.nix
];

environment.systemPackages = with pkgs; [
  #compose2nix
  #calibre
  fluxcd
  
];

}