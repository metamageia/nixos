{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ../nh
    ../musicproduction
    ../gaming
    ../audio
    ../fonts
    ../printing
    ../rclone
  ];
  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system}
    inputs.affinity-nix.packages.x86_64-linux.v3
  ];
}
