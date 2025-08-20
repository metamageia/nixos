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

  networking.firewall.allowedTCPPorts = [8067 8096];
  services.caddy = {
    enable = true;
    globalConfig = ''
      auto_https off
    '';
    virtualHosts.":80".extraConfig = ''
      respond "Hello, world!"
    '';
    virtualHosts.":8067".extraConfig = ''
      reverse_proxy 127.0.0.1:80
    '';
    virtualHosts.":8096".extraConfig = ''
      reverse_proxy 192.168.100.2:8096
    '';
  };
}
