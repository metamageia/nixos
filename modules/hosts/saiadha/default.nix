{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../../desktop-presets/niri

    ../../nvidia
    #../../k3s/agent.nix
    ../../nebula/node.nix
    ../../jellyfin
    ../../n8n
    ../../hermes-agent

    # Users
    ../../users/metamageia

  ];

  hardware.graphics.enable32Bit = true;

  # Removable media (optical drive) — udisks2 is what the desktop uses to
  # enumerate and automount /dev/sr0; without it Dolphin shows no drive.
  services.udisks2.enable = true;
}
