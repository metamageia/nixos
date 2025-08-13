{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    rclone
  ];
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  user="metamageia"
}