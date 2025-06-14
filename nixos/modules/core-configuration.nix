{ config, pkgs, hostName, inputs, system, ... }:

{
  imports =
    [ 
      ./networking.nix
      ./locale.nix
      ./audio.nix
      ./fonts.nix
      ./printing.nix

      # Custom modules to import
      ./apps/cachix.nix
      ./apps/syncthing.nix
  
    ];

  environment.systemPackages = with pkgs; [
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

  nix.gc = {
    automatic = true;
    dates     = ["weekly"];
    options   = "--delete-older-than 30d";
  };

  system.stateVersion = "23.11"; # Do Not Change
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; 

}
