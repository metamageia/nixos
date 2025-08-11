{
  config,
  pkgs,
  hostName,
  inputs,
  system,
  ...
}: {
  imports = [
    ./networking
    ./locale
    ./audio
    ./fonts
    ./printing

    # Custom modules to import
    ./cachix
    ./sops
    ./syncthing
  ];

  environment.systemPackages = with pkgs; [
    wget
    unzip
    unrar
    git
    bash
    inputs.alejandra.defaultPackage.${system}
  ];

  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = ["weekly"];
    options = "--delete-older-than 14d";
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];
}
