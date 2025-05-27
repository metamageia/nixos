{ pkgs, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

  fileSystems."/srv/media" = {
    device = "/home/metamageia/Syncthing/Server_Media";
    fsType = "none";
    options = [ "bind" ];
  };
}
