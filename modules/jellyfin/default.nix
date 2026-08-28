{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../rclone/server_media.nix
  ];
  networking.firewall.allowedTCPPorts = [
    8096
  ];
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    vlc
  ];
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "metamageia";
  };
}
