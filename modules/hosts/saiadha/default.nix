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

    #../../hermes-agent

    # Users
    ../../users/metamageia

    inputs.infernixos.nixosModules.infernixos

    ../../nh
    ../../audio
    ../../fonts
    ../../printing
    ../../rclone
    ../../cua-driver

  ];

  hardware.graphics.enable32Bit = true;
  services.udisks2.enable = true;

  # Second harddrive (7.3 TB media pool, ext4, /dev/sda1) mounted at /srv with
  # metamageia (1000:100) ownership. nofail: media, not boot-critical.
  fileSystems."/srv" = {
    device = "/dev/disk/by-uuid/8fd464fb-a385-4c8a-88d8-f25344c5942a";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.device-timeout=30" ];
  };
  # ext4 has no uid=/gid= mount option, so ownership is applied to the tree.
  # (Shares the tmpfiles list with the /bin/true shim below.)
  systemd.tmpfiles.rules = [
    "d /srv 2775 1000 100 - -"
    "L+ /bin/true - - - - ${pkgs.coreutils}/bin/true"
  ];

  # Discord gateway creds. The 09-06 migration handed hermes to infernixos,
  # which only provisions the API-server key via environmentFiles; the old
  # dotfiles hermes-agent module (commented out below) was the sole carrier
  # of DISCORD_BOT_TOKEN. Upstream regenerates $HERMES_HOME/.env from
  # environmentFiles on every activation, so the stale token in .env was
  # wiped on the first post-migration rebuild and the bot died. Restore the
  # Discord env as an environmentFiles entry so it survives regeneration.
  sops.secrets."hermes-discord" = {
    sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
  };
  sops.templates."hermes-discord-env".content = ''
    DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-discord"}
    DISCORD_ALLOWED_USERS=663086185920331777
    DISCORD_HOME_CHANNEL=1532688784796291164
    DISCORD_DM_CHANNEL=1532707219387187351
  '';
  services.hermes-agent.environmentFiles = lib.mkAfter [
    config.sops.templates."hermes-discord-env".path
  ];

  environment.systemPackages = [
    #inputs.infernixos.packages.${pkgs.stdenv.hostPlatform.system}.pyre
    pkgs.godot
    pkgs.blender
    pkgs.steam
  ];

  infernixos.system.hermesUser = "metamageia";
  # Mnemosyne memory provider for the top-level (default) profile. infernixos
  # deep-merges hermesSettings into services.hermes-agent.settings. Plugin must
  # also be enabled for the in-session hooks. Bank: $HERMES_HOME/memory/hermes-default.db.
  infernixos.system.hermesSettings = {
    plugins.enabled = [ "discord-webhook-bots"  ];
    platform_toolsets = {
      discord = [ "hermes-discord" "video" "video_gen" "computer_use" ];
      cli = [ "hermes-cli" "video" "video_gen" "computer_use" ];
      desktop = [ "hermes-desktop" "computer_use" ];
    };
  };
  infernixos.desktop.enable = true;
  infernixos.desktop.hermesClientUsers = [ "metamageia" ];

  systemd.services.hermes-agent.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    DISPLAY = ":0";
  };


  systemd.services.hermes-agent.serviceConfig.PrivateTmp = lib.mkForce false;
  systemd.services.hermes-agent.serviceConfig.ProtectSystem = lib.mkForce false;
  services.gnome.at-spi2-core.enable = true;

  systemd.services.hermes-backend.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    DISPLAY = ":0";
  };
  systemd.services.hermes-backend.serviceConfig.PrivateTmp = lib.mkForce false;
  systemd.services.hermes-backend.serviceConfig.ProtectSystem = lib.mkForce false;

  services.nebula.networks.mesh.staticHostMap."192.168.100.3" = ["192.168.12.191:4242"];
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
