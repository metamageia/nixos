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

  networking.firewall.allowedTCPPorts = [8096];
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
    virtualHosts.":9876".extraConfig = ''
      reverse_proxy 192.168.100.3:9876
    '';
  };
}
