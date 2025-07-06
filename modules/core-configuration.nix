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
