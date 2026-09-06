{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  imports = [

 
    #../../kitty
    #../../discord
    #../../zen
    #../../awww
    #../../wallust
    #../../quickshell


    inputs.infernixos.homeManagerModules.infernixos
  ];

  programs = {

    bash.enable = true;

  };


  infernixos.desktop.theming.wallpaper.extraDirs = [ ../../../wallpapers ];

  home.username = "metamageia";
  home.homeDirectory = "/home/metamageia";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    obsidian
    vscode
    qbittorrent    
  ];

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
