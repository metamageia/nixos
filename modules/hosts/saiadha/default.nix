{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    # Users
    ../../users/metamageia
  ];
}
