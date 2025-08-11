{
  config,
  system,
  pkgs,
  hostName,
  sopsFile,
  ...
}: {
  users.users.root = {
    extraGroups = ["docker"];
    hashedPassword = "";
  };

  networking.hostName = hostName;
  networking.networkmanager.enable = true;
  system.stateVersion = "24.05";
  nix.settings.experimental-features = ["nix-command" "flakes"];

  imports = [
    "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
    ../../comin
    ../../k3s/initServer.nix
    ../../k3s/lighthouse.nix

    #./cachix
    #./comin
    #./sops
    #./firewall
    #./nebula
    #./k3s
  ];
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [
    docker-compose
    git
    nano
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 2 * 1024;
    }
  ];

  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };
}
