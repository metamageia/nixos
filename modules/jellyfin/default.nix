{
  config,
  pkgs,
  nebulaIP,
  ...
}: {
  imports = [
    ../rclone/server_media.nix
  ];
  networking.firewall.allowedTCPPorts = [
    8096
    80
    443
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
