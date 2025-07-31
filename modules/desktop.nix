{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./home-manager
    # DE / WM
    ./sddm
    ./niri
    ./stylix
  ];

  environment.systemPackages = with pkgs; [
    iosevka
    font-awesome
    material-design-icons
  ];
}
