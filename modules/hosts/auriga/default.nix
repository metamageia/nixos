{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../../desktop-presets/niri

    ../../grub
    ../../nvidia
    #../../k3s/agent.nix
    ../../nebula/node.nix
    #../../comin

    #../../vrising

    # Users
    ../../users/metamageia
  ];

  hardware.graphics.enable32Bit = true;
}
