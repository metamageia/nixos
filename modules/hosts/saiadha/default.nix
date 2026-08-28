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

  # Direct LAN path to auriga when co-located; lighthouse covers it otherwise.
  services.nebula.networks.mesh.staticHostMap."192.168.100.3" = ["192.168.12.191:4242"];
  # Mark the LAN directly reachable so nebula prefers it over the NAT path.
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
