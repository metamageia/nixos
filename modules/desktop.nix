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
}
