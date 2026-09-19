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
    plugins.enabled = [ "discord-webhook-bots" "ponytail" ];
    # Computer-use toolset (background desktop control via cua-driver, packaged
    # in ../../cua-driver). Nix LISTS REPLACE on merge, so these restate the
    # full list registered in the upstream module defaults — a new upstream
    # default toolset would be dropped here, not added.
    platform_toolsets = {
      discord = [ "hermes-discord" "video" "video_gen" "computer_use" ];
      cli = [ "hermes-cli" "video" "video_gen" "computer_use" ];
      # Desktop sessions are served by hermes-backend.service, a different
      # platform key from the gateway's "cli"/"discord" — without this entry
      # the desktop resolves to [hermes-desktop] and computer_use never
      # registers in a desktop session (verified: resolver output).
      desktop = [ "hermes-desktop" "computer_use" ];
    };
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
    # cua-driver (computer_use) is an X11 client. niri's xwayland-satellite owns
    # /tmp/.X11-unix/X0 (mode 0755, user metamageia = this unit's User), so the
    # gateway can drive the desktop through XWayland.
    DISPLAY = ":0";
  };

  # Two things block cua-driver from the gateway unit and are non-negotiable:
  #  - PrivateTmp=true (set by the hermes-agent module) gives the service a
  #    private /tmp, hiding /tmp/.X11-unix -> no X connection at all.
  #    Dropped rather than bind-mounted: this unit already runs with
  #    ProtectHome=false and ReadWritePaths=/home/metamageia, so the private
  #    /tmp buys little here.
  #  - Without at-spi2-core, NixOS exports NO_AT_BRIDGE=1 + GTK_A11Y=none, so
  #    there is no accessibility tree: computer_use still screenshots but
  #    element-index capture/click (its most reliable path) is dead.
  systemd.services.hermes-agent.serviceConfig.PrivateTmp = lib.mkForce false;
  services.gnome.at-spi2-core.enable = true;

  # Desktop sessions are served by hermes-backend.service, not the gateway unit
  # (verified live: the agent's own shell cgroup is hermes-backend.service), so
  # cua-driver is spawned as its child and needs the same X access — patching
  # only hermes-agent above leaves the desktop path with no DISPLAY and a
  # private /tmp. XDG_RUNTIME_DIR is what AT-SPI resolves the a11y bus against;
  # without it, element-index capture is dead even with at-spi core enabled.
  systemd.services.hermes-backend.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    DISPLAY = ":0";
  };
  systemd.services.hermes-backend.serviceConfig.PrivateTmp = lib.mkForce false;

  # Cron restart-safe dispatch is dead without this. The gateway probes
  # `systemd-run --user --scope` availability by exec'ing a hardcoded
  # /bin/true; NixOS ships only /bin/sh, so the probe ALWAYS fails and every
  # cron fire aborts with "cannot create restart-safe systemd scope for
  # gateway child" (all GTD jobs have been failing this way since 09-04).
  # Upstream fixed the probe portably in 7a7ead8 ("use portable /bin/sh probe
  # for systemd-run scope availability"); drop this line once the hermes-agent
  # pin in infernixos/flake.nix moves past that commit.
  # (Merged into the systemd.tmpfiles.rules list above — Nix attrsets can't
  # be defined twice.)

  services.nebula.networks.mesh.staticHostMap."192.168.100.3" = ["192.168.12.191:4242"];
  services.nebula.networks.mesh.settings.local_range = ["192.168.12.0/24"];
}
