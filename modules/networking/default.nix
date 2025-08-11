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
        6443
        2379
        2380
        80
        443
      ];
      allowedUDPPorts = [
        8472
        4242
      ];
    };
    nftables = {
      enable = true;
      ruleset = ''
        table ip nat {
          chain prerouting {
            type nat hook prerouting priority 0; policy accept;
            tcp dport 80  redirect to :32494
            tcp dport 443 redirect to :32380
          }
        }
      '';
    };
  };
  services.resolved = {
    enable = true;
    fallbackDns = ["8.8.8.8"];
  };
}
