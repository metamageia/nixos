{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../nvidia
    ../../k3s/agent.nix
    ../../nebula/node.nix
    ../../jellyfin

    # Users
    ../../users/metamageia
  ];

  environment.systemPackages = with pkgs; [
    minikube
    kubectl
    kustomize
  ];
  virtualisation.docker.enable = true;

}
