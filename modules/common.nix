{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./networking
    ./locale
    ./cachix
    ./sops
  ];

  environment.systemPackages = with pkgs; [
    wget
    unzip
    unrar
    git
    claude-code
  ];

  nix.optimise.automatic = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];
  system.stateVersion = "23.11"; # Do Not Change
}
