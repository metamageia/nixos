{
  pkgs,
  config,
  ...
}: let
  user = "metamageia";
  group = "users";
  localPath = "/home/${user}/Music Production";
  remotePath = "drive:Music Production";
  stateDir = "/var/lib/rclone-music-sync";
in {
  sops.templates."rclone.conf" = {
    owner = user;
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 ${user} ${group} - -"
    "d \"${localPath}\" 0755 ${user} ${group} - -"
  ];

  systemd.services.rclone-music-sync = {
    description = "Bidirectional sync of Music Production folder with Google Drive";
    after = ["network-online.target"];
    wants = ["network-online.target"];

    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = group;
      Nice = 10;
      IOSchedulingClass = "idle";
    };

    script = ''
      set -eu
      CONFIG="${config.sops.templates."rclone.conf".path}"
      STATE="${stateDir}/.resync-done"
      LOCAL="${localPath}"
      REMOTE="${remotePath}"

      COMMON_ARGS=(
        --config "$CONFIG"
        --create-empty-src-dirs
        --drive-skip-gdocs
        --transfers 4
        --checkers 8
      )

      if [ ! -f "$STATE" ]; then
        echo "First run: performing --resync to establish bisync baseline."
        ${pkgs.rclone}/bin/rclone bisync "$REMOTE" "$LOCAL" "''${COMMON_ARGS[@]}" --resync
        touch "$STATE"
      else
        ${pkgs.rclone}/bin/rclone bisync "$REMOTE" "$LOCAL" "''${COMMON_ARGS[@]}" \
          --conflict-resolve newer \
          --conflict-loser delete \
          --max-lock 5m
      fi
    '';
  };

  systemd.timers.rclone-music-sync = {
    description = "Periodic Music Production bisync";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      Persistent = true;
      RandomizedDelaySec = "1min";
    };
  };
}
