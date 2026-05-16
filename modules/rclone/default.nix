{
  pkgs,
  config,
  userValues,
  ...
}: {
  environment.systemPackages = with pkgs; [rclone fuse];

  sops.secrets = {
    "rclone/drive/token" = {
      sopsFile = userValues.sopsFile;
    };
  };

  sops.templates."rclone.conf".content = ''
    [drive]
    type = drive
    scope = drive
    token = ${config.sops.placeholder."rclone/drive/token"}
    team_drive =
  '';

  systemd.tmpfiles.rules = [
    "d /var/cache/rclone-gdrive 0755 root root - -"
  ];

  fileSystems."/gdrive" = {
    device = "drive:";
    fsType = "rclone";
    options = [
      "nofail"
      "allow_other"
      "args2env"
      "config=${config.sops.templates."rclone.conf".path}"
      "vfs-cache-mode=full"
      "vfs-cache-max-size=50G"
      "vfs-cache-max-age=720h"
      "vfs-read-chunk-size=32M"
      "vfs-read-chunk-size-limit=512M"
      "dir-cache-time=72h"
      "poll-interval=1m"
      "cache-dir=/var/cache/rclone-gdrive"
    ];
  };
}
