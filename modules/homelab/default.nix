{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.homelab.nixosModules.homelab
  ];

  environment.systemPackages = with pkgs; [k3s];
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  sops.secrets = {
    "clusterSecret" = {
      sopsFile = ../../secrets/homelab.secrets.yaml;
    };
  };
  homelab = {
    role = "agent";
    tokenFile = config.sops.secrets.clusterSecret.path;
    clusterAddr = "https://auriga.gagelara.com:6443";
    sopsFile = ../../secrets/homelab.secrets.yaml;
  };
  networking.firewall.allowedTCPPorts = [
    6443
    2379
    2380
  ];
  networking.firewall.allowedUDPPorts = [
    8472
  ];
}
