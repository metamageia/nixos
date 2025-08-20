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
  virtualHosts."auriga.gagelara.com".extraConfig = ''
    encode gzip
    file_server
    root * ${
      pkgs.runCommand "testdir" {} ''
        mkdir "$out"
        echo hello world > "$out/example.html"
      ''
    }
  '';
}; 
networking.firewall.allowedTCPPorts = [ 80 443];
}
