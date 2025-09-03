{
  config,
  system,
  pkgs,
  hostName,
  userValues,
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
    #../../comin
    #../../k3s/initServer.nix
    ../../nebula/lighthouse.nix
  ];
  environment.systemPackages = with pkgs; [
    git
    nano
  ];

  swapDevices = [
    {
      device = "/swapfile";
      size = 2 * 1024;
    }
  ];

  networking.firewall.allowedTCPPorts = [8096 9876];
  networking.firewall.allowedUDPPorts = [9876];
  services.caddy = {
    enable = true;
    email = "metamageia@gmail.com";
    globalConfig = ''
      auto_https off
    '';
    virtualHosts.":8096".extraConfig = ''
      reverse_proxy 192.168.100.2:8096
    '';
    virtualHosts."http://jellyfin.auriga.gagelara.com:80".extraConfig = ''
      reverse_proxy 192.168.100.2:8096
    '';
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          iifname "ens3" ip daddr 167.99.123.140 udp dport 9876 \
            dnat to 192.168.100.3:9876
        }
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          oifname "nebula.mesh" ip daddr 192.168.100.3 udp dport 9876 \
            snat to 192.168.100.1
        }
      }
    '';
  };
}
