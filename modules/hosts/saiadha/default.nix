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

  ];

  hardware.graphics.enable32Bit = true;
  services.udisks2.enable = true;

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
  ];

  infernixos.system.hermesUser = "metamageia";
  # Mnemosyne memory provider for the top-level (default) profile. infernixos
  # deep-merges hermesSettings into services.hermes-agent.settings. Plugin must
  # also be enabled for the in-session hooks. Bank: $HERMES_HOME/memory/hermes-default.db.
  infernixos.system.hermesSettings = {
    plugins.enabled = [ "discord-webhook-bots" "ponytail" ];
  };
  infernixos.desktop.enable = true;
  infernixos.desktop.hermesClientUsers = [ "metamageia" ];

  # Cron/kanban restart-safe dispatch needs systemd-run --user, which needs
  # the user session bus. The gateway is a system service, so give it the
  # user-bus env explicitly (mirrors infernixos commit b382be4; drop once
  # that is pushed and the flake.lock is bumped).
  systemd.services.hermes-agent.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    # Ponytail's documented default-mode knob (plugin README): env var wins
    # over ~/.config/ponytail/config.json, which is unset here — without it
    # every session starts at 'full'. Service-level, so spawned workers,
    # daimons, and cron inherit it.
    PONYTAIL_DEFAULT_MODE = "ultra";
  };

  services.nebula.networks.mesh.staticHostMap."192.168.100.3" = ["192.168.12.191:4242"];
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
