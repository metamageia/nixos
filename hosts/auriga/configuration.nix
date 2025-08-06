{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/grub

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
    ../../modules/homelab
  ];

  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${system}
    k3s
  ];

    sops.secrets = {
    "clusterSecret" = {
      sopsFile = ../../secrets/homelab.secrets.yaml;
    };
  };
  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.sops.secrets.clusterSecret.path;
    serverAddr = "http://192.168.12.234:6443";
    extraFlags = [
      "--write-kubeconfig-mode '0644'"
    ];
  };
}
