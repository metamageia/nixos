{
  inputs,
  pkgs,
  config,
  lib,
  userValues,
  nebulaIP,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../../nvidia
    ../../nebula/node.nix
    ../../jellyfin
    ../../niri/default.nix
    ../../sddm

    # Users
    ../../users/metamageia

    ../../nh
    ../../audio
    ../../fonts
    ../../printing
    ../../rclone
  ];

  hardware.graphics.enable32Bit = true;
  services.udisks2.enable = true;

  fileSystems."/srv" = {
    device = "/dev/disk/by-uuid/8fd464fb-a385-4c8a-88d8-f25344c5942a";
    fsType = "ext4";
    options = ["nofail" "x-systemd.device-timeout=30"];
  };
  systemd.tmpfiles.rules = [
    "d /srv 2775 1000 100 - -"
    "L+ /bin/true - - - - ${pkgs.coreutils}/bin/true"
  ];

  sops.secrets."hermes-discord" = {
    sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
  };

  environment.systemPackages = [
    pkgs.godot
    pkgs.blender
    pkgs.steam
    pkgs.kdePackages.dolphin
    inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system}
  ];

  services.nebula.networks.mesh.staticHostMap."192.168.100.3" = ["192.168.12.191:4242"];
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
