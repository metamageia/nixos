{
  pkgs,
  userValues,
  inputs,
  ...
}: {
  imports = [inputs.stylix.nixosModules.stylix];
  stylix = {
    enable = true;
    homeManagerIntegration.autoImport = true;
    image = userValues.wallpaper;
    base16Scheme = ./hermetic-arcanum.yaml;
    polarity = "dark";

    opacity = {
      desktop = 0.90;
      terminal = 0.92;
      applications = 0.95;
      popups = 0.95;
    };

    cursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-light";
      size = 24;
    };

    fonts = {
      serif = {
        package = pkgs.eb-garamond;
        name = "EB Garamond";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 12;
        applications = 11;
        desktop = 10;
        popups = 11;
      };
    };
  };

  stylix.targets.fuzzel.enable = true;
  stylix.targets.waybar.enable = true;
  stylix.targets.niri.enable = true;
}
