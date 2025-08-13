{
  config,
  pkgs,
  inputs,
  system,
  ...
}: {
  imports = [
    ./networking
    ./locale

    # Custom modules to import
    ./cachix
    ./sops
  ];

  environment.systemPackages = with pkgs; [
    wget
    unzip
    git
  ];

  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = ["weekly"];
    options = "--delete-older-than 14d";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "23.11"; # Do Not Change
}
