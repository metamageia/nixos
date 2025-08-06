{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    #../../modules/grub

    ../../modules/core-configuration.nix
    ../../modules/desktop.nix

    # Users
    ../../users/metamageia
    inputs.niri-flake.nixosModules.niri
    inputs.stylix.nixosModules.stylix

    # Special Modules
    ../../modules/musicproduction.nix
    ../../modules/development.nix
    ../../modules/gaming.nix
    #../../modules/homelab
  ];

  environment.systemPackages = with pkgs; [
    #inputs.alejandra.defaultPackage.${system}
    k3s
    kubectl
    kompose
    kubernetes-helm
  ];

  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  sops.secrets = {
    "clusterSecret" = {
      sopsFile = ../../secrets/homelab.secrets.yaml;
    };
  };
  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.sops.secrets.clusterSecret.path;
    extraFlags = [
      "--write-kubeconfig-mode '0644'"
    ];
  };
}
