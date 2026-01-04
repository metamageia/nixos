{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./nh

    #./stylix

    ./musicproduction
    ./gaming
    ./audio
    ./fonts
    ./printing
    ./rclone
  ];
  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${system}
    inputs.affinity-nix.packages.x86_64-linux.v3
    claude-code
  ];
}
