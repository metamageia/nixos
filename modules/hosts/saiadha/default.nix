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

    # Users
    ../../users/metamageia

  ];

  hardware.graphics.enable32Bit = true;
}
