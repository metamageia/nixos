{ config, pkgs, ... }:
{
 
  environment.systemPackages = with pkgs; [
    lutris
    wine
    wineWowPackages.stable
    winetricks
    godot_4
    mindustry
    cataclysm-dda
    cockatrice

    dolphin-emu
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };



  #virtualisation.waydroid.enable = true; #Android Emulator


}








