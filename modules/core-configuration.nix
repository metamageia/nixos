
{ config, pkgs, hostName, inputs, ... }:

{
  imports =
    [ 

      ./networking.nix
      ./locale.nix
      ./audio.nix

      # Custom modules to import
      ./apps/cachix.nix
      ./apps/syncthing.nix
      
      #./apps/hyprland.nix
      ./apps/kde-plasma.nix      
      #./apps/kde-plasma-wayland.nix

      #inputs.home-manager.nixosModules.home-manager

    ];

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = with pkgs; [ gutenprint ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    unzip
    unrar
    git
    bash
    home-manager
    brave
    rclone
    jmtpfs
    nix-tree
  ];

fonts.packages = with pkgs; [
  corefonts
  vistafonts
];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ]; # Enable the use of Flakes

}
