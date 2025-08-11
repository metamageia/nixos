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
    ../../k3s/node.nix

    # Users
    ../../users/metamageia
  ];
}
