{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ rclone fuse ];

  systemd.services."mount-rclone" = {
    description = "Mount Google Drive via rclone";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rclone}/bin/rclone mount gdrive:/Server_Media/ /root/media --daemon";
      ExecStop  = "${pkgs.fuse3}/bin/fusermount3 -u /mnt/media";
      Restart   = "on-failure";
    };
  };
}
