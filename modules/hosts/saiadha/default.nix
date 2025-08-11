{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../core-configuration.nix
    ../../desktop.nix
    ../../homelab.nix

    # Users
    ../../users/metamageia
  ];

  environment.systemPackages = with pkgs; [
  ];
}
