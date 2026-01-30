{
  config,
  pkgs,
  inputs,
  ...
}: {
  fonts.packages = with pkgs; [
    corefonts
    vista-fonts
    eb-garamond
    inter
    nerd-fonts.iosevka
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
  ];
  environment.systemPackages = with pkgs; [
    iosevka
    font-awesome
    material-design-icons
  ];
}
