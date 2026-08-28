{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../../desktop-presets/niri
    ../../nebula/node.nix

    # Users
    ../../users/metamageia
  ];

  system.stateVersion = "23.11"; # Do Not Change

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  boot.loader.systemd-boot.enable = true; # turn on systemd-boot :contentReference[oaicite:6]{index=6}
  boot.loader.efi.efiSysMountPoint = "/boot"; # ensure it writes to your ESP mount at /boot :contentReference[oaicite:7]{index=7}

  # Hermes desktop app (Electron GUI). Thin client only — setseke does NOT run
  # a hermes-agent gateway/service; it reaches saiadha's gateway (which owns
  # skills, memory, sessions, cron) via the desktop app's SSH/remote connection.
  # Same pinned rev as saiadha (modules/hermes-agent/default.nix). At this pin
  # the desktop is exposed ONLY as a flake package (no services/programs
  # option), so it goes into systemPackages directly.
  environment.systemPackages = [
    #inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
  ];
}
