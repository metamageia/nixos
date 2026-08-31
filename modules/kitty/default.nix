{
  pkgs,
  ...
}: {
  # Kitty is NOT managed via programs.kitty: that module auto-generates and
  # symlinks a kitty.conf from the nix store, which collides with wallust's
  # ownership of ~/.config/kitty/kitty.conf (same pattern as fuzzel). Instead
  # we provide the package and let wallust render the full config from
  # kitty.tmpl. shell_integration is set in that template.
  home.packages = with pkgs; [
    kitty
  ];
}
