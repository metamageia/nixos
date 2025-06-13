{ config, pkgs, ... }:
{

imports = [
  ./apps/jellyfin.nix
];

environment.systemPackages = with pkgs; [
  compose2nix
];
}