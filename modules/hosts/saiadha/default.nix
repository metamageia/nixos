{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common.nix

    ../../desktop-presets/plasma

    ../../nvidia
    #../../k3s/agent.nix
    ../../nebula/node.nix

    #../../docker
    #../../pihole
    ../../jellyfin

    #../../cloudflared
    ../../virt-manager

    # Users
    ../../users/metamageia

    # ../../comfyui.nix
  ];
}
