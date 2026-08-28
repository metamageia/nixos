{...}: {
  imports = [
    ../../desktop-presets

    ../../niri
    ../../sddm
  ];

  home-manager.sharedModules = [
    ../../niri/home.nix
    ../../waybar
    ../../fuzzel
  ];
}
