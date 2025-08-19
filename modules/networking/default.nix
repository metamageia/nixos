{
  config,
  pkgs,
  hostName,
  ...
}: {
  imports = [
    ../avahi
    ../openssh
  ];

  networking = {
    hostName = hostName;
    wireless.iwd.enable = true;
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
        8096
      ];
      allowedUDPPorts = [
        4242
        5353
        7359
        1900
      ];
    };
  };
}
