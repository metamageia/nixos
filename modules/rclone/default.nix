{ pkgs, config, hostName, ... }:
{

  environment.systemPackages = with pkgs; [
    rclone
  ];
  systemd.services."mount-rclone" = {
    script = ''
        rclone mount gdrive:/Server_Media/ /root/media --daemon
    '';
    serviceConfig = {
        Type = "oneshot";
    };
  };
}