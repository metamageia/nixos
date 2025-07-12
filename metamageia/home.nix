{ config, pkgs, inputs, wallpaper, ... }:

{

imports = [
  ../modules/apps/niri/default.nix
  ../modules/apps/swww/default.nix
  ../modules/apps/waybar/default.nix
  ../modules/fuzzel/hm.nix
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



  home.file = {
  };
 
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
