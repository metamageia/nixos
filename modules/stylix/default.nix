{
  pkgs,
  userValues,
  inputs,
  ...
}: {
  imports = [inputs.stylix.nixosModules.stylix];

  # autoImport skips the home-manager module while stylix is disabled, but
  # niri-flake's stylix integration reads config.stylix.enable unconditionally.
  home-manager.sharedModules = [
    inputs.stylix.homeModules.stylix
    # Stylix normally disables its overlays under useGlobalPkgs, but that shim
    # is gated on stylix.enable, which is off here.
    {stylix.overlays.enable = false;}
  ];

  stylix = {
    enable = false;
    homeManagerIntegration.autoImport = true;
    image = userValues.wallpaper;
  };

  #stylix.targets.fuzzel.enable = true;
  #stylix.targets.waybar.enable = true;
  #stylix.targets.niri.enable = true;
}
