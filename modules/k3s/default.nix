{
  config,
  pkgs,
  sopsFile,
  nebulaIP,
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
    enable = true;
    role = "agent";
    tokenFile = config.sops.secrets.clusterSecret.path;
    serverAddr = "https://192.168.100.1:6443";
    extraFlags = ["--node-ip=${nebulaIP}"];
  };

  systemd.services."k3s.service" = {
    wants = ["nebula.service"];
    after = ["nebula.service"];
  };
}
