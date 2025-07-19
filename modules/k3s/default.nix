{ config, pkgs, ... }:
{

imports = [
];

environment.systemPackages = with pkgs; [
    kubectl
    kompose
    kubernetes-helm
];

  networking.firewall.allowedTCPPorts = [
    6443 
    8443 
  ];

  services.k3s = {
    enable = true;
    role = "server";
  };


}