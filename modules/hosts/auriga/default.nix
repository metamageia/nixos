{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../grub
    ../../nvidia
    ../../k3s/agent.nix
    #../../nebula/node.nix
    ../../comin

    #../../vrising

    # Users
    ../../users/metamageia
  ];
}
