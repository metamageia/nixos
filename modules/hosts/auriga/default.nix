{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../grub
    ../../nvidia

    # Users
    ../users/metamageia
  ];
}
