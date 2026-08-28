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
    "d /var/cache/rclone-server-media 0755 root root - -"
  ];

  fileSystems."/media" = {
    device = "drive:Server_Media";
    fsType = "rclone";
    options = [
      "nofail"
      "rw"
      "allow_other"
      "args2env"
      "config=${config.sops.templates."rclone.conf".path}"
      "uid=1000"
      "gid=100"
      "file-perms=0664"
      "dir-perms=0775"
      "vfs-cache-mode=full"
      "vfs-cache-max-size=50G"
      "vfs-cache-max-age=720h"
      "vfs-read-chunk-size=32M"
      "vfs-read-chunk-size-limit=512M"
      "dir-cache-time=72h"
      "poll-interval=1m"
      "cache-dir=/var/cache/rclone-server-media"
    ];
  };
}
