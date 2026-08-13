{
  inputs,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    #../../desktop-presets/niri

    ../../grub
    ../../nvidia
    #../../k3s/agent.nix
    ../../nebula/node.nix
    #../../comin

    #../../vrising

    # Users
    #../../users/metamageia
  ];

  hardware.graphics.enable32Bit = true;

  # v6 addrs make nebula advertise endpoints v4-only peers can't answer; mesh is IPv4.
  networking.enableIPv6 = false;

  # Direct LAN path to saiadha when co-located; lighthouse covers it otherwise.
  services.nebula.networks.mesh.staticHostMap."192.168.100.2" = ["192.168.12.234:4242"];
  # Mark the LAN directly reachable so nebula prefers it over the NAT path.
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
