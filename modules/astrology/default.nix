{
  config,
  pkgs,
  lib,
  ...
}: let
  # Python environment with all dependencies
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.ephem
    ps.pygobject3
    ps.pycairo
  ]);

  # Planetary hours script
  planetary-hours = pkgs.writeScriptBin "planetary-hours" ''
    #!${pythonEnv}/bin/python3
    ${builtins.readFile ./planetary-hours.py}
  '';

  # Astrolog GUI wrapper with proper GTK environment
  astrolog-gui = pkgs.writeShellScriptBin "astrolog-gui" ''
    export GI_TYPELIB_PATH="${pkgs.gtk4}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0:${pkgs.graphene}/lib/girepository-1.0:${pkgs.harfbuzz}/lib/girepository-1.0:${pkgs.glib}/lib/girepository-1.0''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
    export XDG_DATA_DIRS="${pkgs.gtk4}/share:${pkgs.gsettings-desktop-schemas}/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    exec ${pythonEnv}/bin/python3 ${./astrolog-gui.py} "$@"
  '';
in {
  # System-wide astrology packages
  environment.systemPackages = with pkgs; [
    # Astrology software
    astrolog # Classic astrology program
    stellarium # Planetarium - useful for planetary positions

    # Terminal tools
    astroterm # Celestial viewer for terminal

    # Custom scripts
    planetary-hours
    astrolog-gui

    # GTK4 dependencies for GUI
    gtk4
    gobject-introspection
    gdk-pixbuf
    pango
    graphene
  ];

  # Home-manager configuration for user-level settings
  home-manager.sharedModules = [
    {
      home.packages = [
        planetary-hours
        astrolog-gui
      ];
    }
  ];
}
