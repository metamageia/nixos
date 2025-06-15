{ pkgs, ... }:
{

  stylix = {
    enable = true;
    homeManagerIntegration.autoImport = true;
    #base16Scheme = "${pkgs.base16-schemes}/share/themes/brushtrees.yaml";
    image = ./wallhaven-je8p1y.jpg;
    stylix.targets.sway.enable = true;
    stylix.targets.sway.useWallpaper = true;  
  };

}
