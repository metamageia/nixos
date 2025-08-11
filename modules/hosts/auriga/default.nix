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

    # Users
    ../../users/metamageia
  ];
}
