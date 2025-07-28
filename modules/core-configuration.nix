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
      ./cachix/default.nix
      ./syncthing/default.nix
      ./sops/default.nix
  
    ];

  environment.systemPackages = with pkgs; [
    wget
    unzip
    unrar
    git
    bash
    alacritty
  ];

  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates     = ["weekly"];
    options   = "--delete-older-than 14d";
  };

  system.stateVersion = "23.11"; # Do Not Change
  nix.settings.experimental-features = [ "nix-command" "flakes" ]; 

}
