{
  config,
  pkgs,
  hostName,
  ...
}: {
  imports = [
    #../avahi
    ../openssh
  ];

  networking = {
    hostName = hostName;
    wireless.iwd.enable = true;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    firewall = {
      allowedTCPPorts = [
        2379
        2380
        80
        443
      ];
      allowedUDPPorts = [
        4242
        7359
        1900
      ];
    };
  };
}
