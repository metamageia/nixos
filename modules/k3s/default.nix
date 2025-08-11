{
  config,
  pkgs,
  sopsFile,
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
      sopsFile = sopsFile;
    };
  };

  services.k3s = {
    role = "agent";
    tokenFile = config.sops.secrets.clusterSecret.path;
    serverAddr = "https://192.168.100.1:6443";
  };
}
