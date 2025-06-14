{ config, pkgs, inputs, ... }:
{
 home-manager.users.metamageia = import ../../home/users/metamageia/home.nix;
  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };
}