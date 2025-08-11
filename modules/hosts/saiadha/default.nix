{
  inputs,
  system,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../core-configuration.nix
    ../../desktop.nix
    ../../homelab.nix

    # Users
    ../../users/metamageia
    
  ];

  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${system}
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
