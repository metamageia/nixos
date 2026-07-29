{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../common.nix

    ../../desktop-presets/niri

    ../../nvidia
    #../../k3s/agent.nix
    ../../nebula/node.nix
    ../../jellyfin
    ../../hermes-agent

    # Users
    ../../users/metamageia

  ];

  hardware.graphics.enable32Bit = true;
}
