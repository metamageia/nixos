{ config, pkgs, ... }:
{

virtualisation.docker.enable = true;

imports = [
  ./apps/jellyfin.nix
   ./apps/omnivore.nix
];



}