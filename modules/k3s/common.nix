{
  config,
  pkgs,
  sopsFile,
  nebulaIP,
  ...
}: {
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
    extraFlags = [
      "--node-ip=${nebulaIP}"
      "--flannel-iface=nebula.mesh"
      "--flannel-mtu=1280"
    ];
  };

  systemd.services."k3s.service" = {
    wants = ["nebula.service"];
    after = ["nebula.service"];
  };
}
