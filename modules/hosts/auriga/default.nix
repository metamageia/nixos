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

  networking.enableIPv6 = false;

  services.nebula.networks.mesh.staticHostMap."192.168.100.2" = ["192.168.12.234:4242"];
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
