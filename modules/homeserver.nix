{ config, pkgs, ... }:
{

virtualisation.docker.enable = true;

imports = [
  ./apps/jellyfin.nix
  ./apps/omnivore.nix
];

  environment.systemPackages = with pkgs; [
    compose2nix
  ];

}