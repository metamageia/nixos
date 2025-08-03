{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    lutris
    #wine
    #wineWowPackages.stable
    #winetricks
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
