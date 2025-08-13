{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./sddm
    ./niri
    ./stylix
    ./musicproduction
    ./gaming
    ./audio
    ./fonts
    ./printing
  ];
  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${system}
  ];
}
