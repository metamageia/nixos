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
      checkReversePath = "loose";
      trustedInterfaces = ["cni0" "flannel.1"];

      allowedTCPPorts = [
        6443
        2379
        2380
        80
        443
        8096
        30642
        32630
        30231
        31443
        30080
        30443
      ];
      allowedUDPPorts = [
        8472
        4242
        5353
        7359
        1900
      ];
    };
  };
}
