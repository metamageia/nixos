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

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority -100; policy accept;
          iifname "eth0" tcp dport 80  dnat to 192.168.100.1:32417;
          iifname "eth0" tcp dport 443 dnat to 192.168.100.1:31260;
        }

        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "nebula.mesh" ip daddr 192.168.100.1 tcp dport { 32417, 31260 } masquerade;
        }
      }
    '';
  };
}
