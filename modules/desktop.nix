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
  ];
  environment.systemPackages = with pkgs; [
    inputs.alejandra.defaultPackage.${system}
  ];
}
