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

  services.caddy = {
    enable = true;
    email = "metamageia@gmail.com";
    virtualHosts."localhost".extraConfig = ''
      respond "Hello, world!"
    '';
    virtualHosts."auriga.gagelara.com".extraConfig = ''
    reverse_proxy http://localhost
  '';
  };
}
