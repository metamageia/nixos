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
    #../../nebula/lighthouse.nix
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

  networking.firewall.allowedTCPPorts = [8067];
  services.caddy = {
    enable = true;
    globalConfig = ''
      auto_https off
    '';
    virtualHosts."http://localhost:80".extraConfig = ''
      respond "Hello, world!"
    '';
    virtualHosts.":8067".extraConfig = ''
      reverse_proxy 127.0.0.1:80
    '';
  };
}
