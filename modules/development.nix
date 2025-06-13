{config, pkgs, ... }:
{

environment.systemPackages = with pkgs; [

vscode
neovim
jq
];

programs.adb.enable = true;
users.users.metamageia.extraGroups = ["adbusers"];

}
