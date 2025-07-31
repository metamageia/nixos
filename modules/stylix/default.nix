{
  pkgs,
  wallpaper,
  ...
}: {
  stylix = {
    enable = true;
    homeManagerIntegration.autoImport = true;
    image = wallpaper;
    opacity.desktop = 0.25;
    fonts = {
      serif = {
        package = pkgs.font-awesome;
        name = "font-awesome";
      };

      sansSerif = {
        package = pkgs.font-awesome;
        name = "font-awesome";
      };

      monospace = {
        package = pkgs.font-awesome;
        name = "font-awesome";
      };

      emoji = {
        package = pkgs.material-design-icons;
        name = "material-design-icons";
      };
    };
  };
}
