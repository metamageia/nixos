{config, pkgs, ... }:
{

environment.systemPackages = with pkgs; [
    vscode
    neovim
    jq
    awscli2
];

# Android development
programs.adb.enable = true;
users.users.metamageia.extraGroups = ["adbusers"];

}
