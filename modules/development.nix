{config, pkgs, ... }:
{

environment.systemPackages = with pkgs; [
    vscode
    jq
    awscli2

    code-cursor

    #direnv tools
    #direnv
    #nix-direnv
    #vscode-extensions.mkhl.direnv

];


# Docker
virtualisation.docker.enable = true;
users.users.metamageia = {  
    extraGroups = [ "docker" "adbusers"];
};

# Hook direnv
#programs.bash.interactiveShellInit = ''eval "$(direnv hook bash)"'';

# Android development
#programs.adb.enable = true;

}
