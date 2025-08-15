{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../rclone/server_media.nix
  ];
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "metamageia";
  };
}
