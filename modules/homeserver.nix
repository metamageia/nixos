{ config, pkgs, ... }:
{

imports = [
  #./apps/jellyfin.nix
];

environment.systemPackages = with pkgs; [
  #compose2nix
  #calibre
  fluxcd
];

  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)  ];
  ];

  services.k3s = {
    enable = true;
    role = "server";
  };


}