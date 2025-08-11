{
  config,
  pkgs,
  inputs,
  ...
}: {
  fonts.packages = with pkgs; [
    corefonts
    vistafonts
  ];
  environment.systemPackages = with pkgs; [
    iosevka
    font-awesome
    material-design-icons
  ];
}
