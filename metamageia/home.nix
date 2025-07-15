{ config, pkgs, inputs, wallpaper, ... }:

{

imports = [
  ../modules/niri/default.nix
  ../modules/swww/default.nix
  ../modules/waybar/default.nix
  ../modules/fuzzel/default.nix
];

  home.username = "metamageia";
  home.homeDirectory = "/home/metamageia";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    obsidian
    #scribus
    wget
    unzip
    unrar
    git
    bash
    #rclone
    #jmtpfs
    #nix-tree
    alacritty
    #librewolf
    inputs.zen-browser.packages."${system}".default
    slack
  ];

  stylix.targets.vscode.enable = true; 


  home.file = {
  };
 
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
