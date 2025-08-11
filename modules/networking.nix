{
  config,
  pkgs,
  hostName,
  ...
}: {
  networking.hostName = hostName;
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Enable and configure Avahi for mDNS support
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

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

  services.resolved = {
    enable = true;
    fallbackDns = ["8.8.8.8"];
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
