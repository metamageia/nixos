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
