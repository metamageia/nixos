{config, pkgs, ... }:
{

environment.systemPackages = with pkgs; [
    vscode
    jq
    awscli2

    #direnv tools
    direnv
    nix-direnv
    vscode-extensions.mkhl.direnv
];

# Android development
programs.adb.enable = true;
users.users.metamageia.extraGroups = ["adbusers"];

}
