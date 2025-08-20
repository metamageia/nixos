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
    ../../k3s/agent.nix
    #../../nebula/node.nix

    #../../docker
    #../../pihole
    ../../jellyfin

    # Users
    ../../users/metamageia
  ];

  networking.nameservers = ["8.8.8.8" "1.1.1.1"];
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
  '';
}
