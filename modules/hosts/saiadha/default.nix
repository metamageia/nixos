{
  inputs,
  pkgs,
  config,
  lib,
  nebulaIP,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../../nvidia
    ../../nebula/node.nix
    ../../jellyfin

    #../../hermes-agent

    # Users
    ../../users/metamageia

    inputs.infernixos.nixosModules.infernixos

    ../../nh
    ../../audio
    ../../fonts
    ../../printing
    ../../rclone

  ];

  hardware.graphics.enable32Bit = true;
  services.udisks2.enable = true;

  environment.systemPackages = [
    #inputs.infernixos.packages.${pkgs.stdenv.hostPlatform.system}.pyre
  ];

  infernixos.system.hermesUser = "metamageia";
  infernixos.desktop.enable = true;
  infernixos.desktop.hermesClientUsers = [ "metamageia" ];

  services.nebula.networks.mesh.staticHostMap."192.168.100.3" = ["192.168.12.191:4242"];
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
