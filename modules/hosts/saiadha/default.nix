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

    #../../cloudflared

    # Users
    ../../users/metamageia
  ];
}
