{ config, pkgs, ... }:
{

imports = [
];

environment.systemPackages = with pkgs; [
   # K8S Testing
    #minikube
    kubectl
    kompose
];

  networking.firewall.allowedTCPPorts = [
    6443 
  ];

  services.k3s = {
    enable = true;
    role = "server";
  };


}