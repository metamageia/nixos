{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../nebula/node.nix

    # Users
    ../../users/metamageia

    ../../nh
    ../../audio
    ../../fonts
  ];

  system.stateVersion = "23.11";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.efiSysMountPoint = "/boot";


  environment.systemPackages = [
    pkgs.kdePackages.dolphin
  ];
}
