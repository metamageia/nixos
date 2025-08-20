{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../nvidia
    #../../k3s/agent.nix
    ../../nebula/node.nix

    #../../docker
    #../../pihole
    ../../jellyfin

    # Users
    ../../users/metamageia
  ];

  services.caddy = {
    enable = true;
    virtualHosts."192.168.100.2".extraConfig = ''
      reverse_proxy http://192.168.100.2:8096
    '';
  };
}
