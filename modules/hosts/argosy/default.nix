{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    # Users
    ../users/metamageia
  ];

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  boot.loader.systemd-boot.enable = true; # turn on systemd-boot :contentReference[oaicite:6]{index=6}
  boot.loader.efi.efiSysMountPoint = "/boot"; # ensure it writes to your ESP mount at /boot :contentReference[oaicite:7]{index=7}
}
