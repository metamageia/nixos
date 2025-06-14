{ config, pkgs, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true; 
  home-manager.backupFileExtension = "backup";


# --- Users --- #
  home-manager.users.metamageia = import ../../home/users/metamageia/home.nix;
  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };
}
