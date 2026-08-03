{
  config,
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
    virtualHosts."http://jellyfin.arcanum.gagelara.com:80".extraConfig = ''
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
          # No address literal on purpose: an IP change should be a Route 53
          # edit only. Public-destined traffic on ens3 is matched by
          # excluding the private range rather than naming the droplet IP.
          iifname "ens3" ip daddr != 10.0.0.0/8 udp dport 9876 \
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
