{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    #../../modules/grub

    ../../modules/core-configuration.nix
    ../../modules/desktop.nix

    # Users
    ../../users/metamageia
    inputs.niri-flake.nixosModules.niri
    inputs.stylix.nixosModules.stylix

    # Special Modules
    ../../modules/musicproduction.nix
    ../../modules/development.nix
    ../../modules/gaming.nix
    ../../modules/homelab
  ];

  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${system}
    k3s
    kubectl
    kompose
    kubernetes-helm
  ];

  hardware.graphics = {
    enable = true;
  };
  
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
