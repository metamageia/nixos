{
  config,
  pkgs,
  nebulaIP,
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
  services.caddy = {
    enable = true;
    virtualHosts."jellyfin.auriga.gagelara.com".extraConfig = ''
      reverse_proxy http://${nebulaIP}:8096
    '';
  };
}
