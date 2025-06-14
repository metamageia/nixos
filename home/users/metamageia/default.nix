{ config, pkgs, inputs, ... }:
{ 
  home-manager ={
    extraSpecialArgs = { inherit inputs; };
    users = { metamageia = import ./home.nix; };
  };

  users.users.metamageia = {
    isNormalUser = true;
    description = "Metamageia";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };
}