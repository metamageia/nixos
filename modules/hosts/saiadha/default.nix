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
    ../../nebula/node.nix

    # Users
    ../../users/metamageia
  ];
  system.stateVersion = "23.11"; # Do Not Change
}
