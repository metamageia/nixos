{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./home-manager
    # DE / WM
    ./lightdm
    ./niri
    ./stylix
  ];

  environment.systemPackages = with pkgs; [
    iosevka
    font-awesome
    material-design-icons
  ];
}
