{
  config,
  pkgs,
  inputs,
  wallpaper,
  ...
}: {
  imports = [
    ../../alacritty
    ../../niri/home.nix
    ../../swww
    ../../waybar
    ../../fuzzel
    ../../zen
    ../../syncthing
  ];

  home.username = "metamageia";
  home.homeDirectory = "/home/metamageia";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    obsidian
    vscode
    qbittorrent
  ];

  stylix.targets.vscode.enable = true;

  home.file = {
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
