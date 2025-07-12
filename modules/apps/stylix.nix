{ pkgs, wallpaper, ... }:
{

  stylix = {
    enable = true;
    homeManagerIntegration.autoImport = true;
    #base16Scheme = "${pkgs.base16-schemes}/share/themes/brushtrees.yaml";
    image = wallpaper;
  };


}
