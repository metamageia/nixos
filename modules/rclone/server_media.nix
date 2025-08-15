{
  pkgs,
  config,
  sopsFile,
  ...
}: {
  environment.systemPackages = with pkgs; [rclone fuse];

  sops.secrets = {
    "rclone/drive/token" = {
      sopsFile = sopsFile;
    };
  };

  environment.etc."rclone.conf".text = ''
    [drive]
    type = drive
    scope = drive
    token = ${config.sops.secrets."rclone/drive/token".path}
    team_drive =
  '';

  fileSystems."media" = {
    device = "drive:Server_Media";
    fsType = "rclone";
    options = [
      "nofail"
      "allow_other"
      "args2env"
      "config=/etc/rclone.conf"
    ];
  };
}
