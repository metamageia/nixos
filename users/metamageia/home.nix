{ config, pkgs, inputs, wallpaper, ... }:

{

imports = [
  ../../modules/niri/home.nix
  ../../modules/swww
  ../../modules/waybar
  ../../modules/fuzzel
  ../../modules/zen
];

  home.username = "metamageia";
  home.homeDirectory = "/home/metamageia";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "23.11"; 

  home.packages = with pkgs; [
    obsidian
  ];

  stylix.targets.vscode.enable = true; 

  home.file = {
  };
 
  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
