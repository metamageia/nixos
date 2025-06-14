{ config, pkgs, inputs, ... }:

{
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
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout
    # '';

    ".config/niri/config.kdl".source = niri/config.kdl;
  };
 
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.home-manager.enable = true;
}
