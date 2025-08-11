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

    # Users
    ../../users/metamageia
  ];
}
