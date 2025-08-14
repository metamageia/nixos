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
        8096
        32417
        31260
      ];
      allowedUDPPorts = [
        8472
        4242
        5353
        7359
        1900
      ];
    };
    nftables = {
      enable = true;
      ruleset = ''
        table ip nat {
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;
            tcp dport 80  redirect to :32417
            tcp dport 443 redirect to :31260
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
