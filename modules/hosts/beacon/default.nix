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
  nix.settings.experimental-features = ["nix-command" "flakes"];

  imports = [
    ../../common.nix
    ../../comin
    ../../k3s/initServer.nix
    ../../nebula/lighthouse.nix

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

  services.k3s = {
    extraFlags = [
      "--node-external-ip=134.199.241.26"
      "--node-label" "svccontroller.k3s.cattle.io/enablelb=true"
    ];
  };
}
