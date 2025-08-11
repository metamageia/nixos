{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
  ];

  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  environment.systemPackages = with pkgs; [
    k3s
    kubectl
    kustomize
    kubernetes-helm
  ];

  sops.secrets = {
    "clusterSecret" = {
      sopsFile = config.homelab.sopsFile;
    };
  };

  services.k3s = {
    role = "agent";
    tokenFile = config.sops.secrets.clusterSecret.path;
    clusterAddr = "https://192.168.100.1:6443";
    sopsFile = ../../secrets/homelab.secrets.yaml;
  };
  networking.firewall.allowedTCPPorts = [
    6443
    2379
    2380
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [
    8472
    4242
  ];
}
