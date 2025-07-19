{ config, pkgs, ... }:
{

imports = [
  ./k3s/default.nix
  ./default/default.nix
];

environment.systemPackages = with pkgs; [
  wireguard-tools
];

}