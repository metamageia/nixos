{config, pkgs, ... }:
{

environment.systemPackages = with pkgs; [

vscode
neovim
];

programs.adb.enable = true;
users.users.metamageia.extraGroups = ["adbusers"];

}
