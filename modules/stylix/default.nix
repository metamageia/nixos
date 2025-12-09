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

  #stylix.targets.fuzzel.enable = true;
  #stylix.targets.vscode.enable = true;
  #stylix.targets.waybar.enable = true;
  #stylix.targets.zen-browser.enable = true;
  #stylix.targets.niri.enable = true;
}
