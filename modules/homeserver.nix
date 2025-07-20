{ config, pkgs, ... }:
{

imports = [
  ./k3s/default.nix
  #./rclone/default.nix
];

environment.systemPackages = with pkgs; [
  wireguard-tools
];

}