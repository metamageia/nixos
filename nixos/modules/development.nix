{config, pkgs, ... }:
{

environment.systemPackages = with pkgs; [
    vscode
    neovim
    jq
];

# Android development
programs.adb.enable = true;
users.users.metamageia.extraGroups = ["adbusers"];

}
