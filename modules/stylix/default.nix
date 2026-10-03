{
  pkgs,
  userValues,
  inputs,
  ...
}: {
  imports = [inputs.stylix.nixosModules.stylix];

  home-manager.sharedModules = [
    inputs.stylix.homeModules.stylix

    {stylix.overlays.enable = false;}
  ];

  stylix = {
    enable = false;
    homeManagerIntegration.autoImport = true;

  };


}
