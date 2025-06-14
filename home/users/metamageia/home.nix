{ config, pkgs, inputs, ... }:

{

imports = [
  ./niri/config/kdl.nix
];

  home.username = "metamageia";
  home.homeDirectory = "/home/metamageia";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    obsidian
    scribus
    wget
    unzip
    unrar
    git
    bash
    rclone
    jmtpfs
    nix-tree
    alacritty
    fuzzel
    inputs.zen-browser.packages."${system}".generic
  ];

  
  home.file = {
  };
 
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
