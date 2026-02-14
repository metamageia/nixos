{
  config,
  pkgs,
  ...
}: {
  imports = [
  ];
  environment.systemPackages = with pkgs; [
    lutris
    libvdpau
    speex
    libtheora
    libgudev

    wine
    wineWow64Packages.stable
    winetricks
    #godot_4
    mindustry
    #cataclysm-dda
    #cockatrice
    #dolphin-emu
  ];

  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };
}
