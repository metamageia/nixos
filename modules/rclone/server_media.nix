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

  fileSystems."/media" = {
    device = "drive:Server_Media";
    fsType = "rclone";
    options = [
      "nofail"
      "allow_other"
      "args2env"
      "config=${config.sops.templates."rclone.conf".path}"
      "uid=1000"
      "gid=100"
      "file-perms=0664"
      "dir-perms=0775"
      "vfs-cache-mode=full"
    ];
  };
}
