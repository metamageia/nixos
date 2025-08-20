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
  networking.firewall.allowedUDPPorts = [9876 9877];
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/mholt/caddy-l4@v0.0.0-20250102174933-6e5f5e311ead"
      ];
      hash = "sha256-Ji9pclVcnxTZrnVlDhYffbG+adi+tpNEFgXNH+bsym8="; # build once; Nix will tell you the correct hash
    };
    config = ''
      {
        auto_https off
        layer4 {
          udp/:9876 {
            route {
              proxy udp/192.168.100.3:9876
            }
          }
          udp/:9877 {
            route {
              proxy udp/192.168.100.3:9877
            }
          }
        }
      }

      :8096 {
        reverse_proxy 192.168.100.2:8096
      }

      http://jellyfin.auriga.gagelara.com:80 {
        reverse_proxy 192.168.100.2:8096
      }
    '';
  };
}
