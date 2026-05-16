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


  };

  #stylix.targets.fuzzel.enable = true;
  #stylix.targets.waybar.enable = true;
  #stylix.targets.niri.enable = true;
}
