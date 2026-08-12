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
    twitter-color-emoji
  ];
  fonts.fontconfig.defaultFonts.emoji = [
    "Twitter Color Emoji"
    "Noto Color Emoji"
  ];
  environment.systemPackages = with pkgs; [
    iosevka
    font-awesome
    material-design-icons
  ];
}
