{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../../nebula/node.nix


    # Users
    ../../users/metamageia

    inputs.infernixos.nixosModules.infernixos

    ../../nh
    ../../audio
    ../../fonts
  ];

  system.stateVersion = "23.11"; 

  hardware.bluetooth.enable = true; 
  hardware.bluetooth.powerOnBoot = true; 

  boot.loader.systemd-boot.enable = true; 
  boot.loader.efi.efiSysMountPoint = "/boot"; 

  infernixos.system.hermesUser = "metamageia";
  infernixos.desktop.enable = true;
  infernixos.desktop.hermesClientUsers = [ "metamageia" ];

  environment.systemPackages = [
    #inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
    #pkgs.kdePackages.dolphin
  ];
}
