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
  # System default sans-serif = Inter, the same font the QuickShell bar and
  # fuzzel use, so the whole desktop (system UI, launcher, bar) speaks one face.
  fonts.fontconfig.defaultFonts.sansSerif = [
    "Inter"
  ];
  environment.systemPackages = with pkgs; [
    iosevka
    font-awesome
    material-design-icons
  ];
}
