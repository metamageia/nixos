{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # DE / WM
    ./sddm
    ./niri
    ./stylix
    ./musicproduction
    ./gaming
  ];
}
