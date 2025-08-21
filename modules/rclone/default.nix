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

  fileSystems."/gdrive" = {
    device = "drive:";
    fsType = "rclone";
    options = [
      "nofail"
      "allow_other"
      "args2env"
      "config=${config.sops.templates."rclone.conf".path}"
    ];
  };
}
