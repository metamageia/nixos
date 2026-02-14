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

  # Astrolog GUI - proper GTK4 Python application with wrapGAppsHook4
  astrolog-gui = pkgs.stdenv.mkDerivation {
    pname = "astrolog-gui";
    version = "1.0";
    src = ./astrolog-gui.py;
    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.wrapGAppsHook4
      pkgs.gobject-introspection
    ];

    buildInputs = [
      pythonEnv
      pkgs.gtk4
      pkgs.libadwaita
      pkgs.gdk-pixbuf
      pkgs.pango
      pkgs.graphene
      pkgs.harfbuzz
      pkgs.cairo
      pkgs.glib
      pkgs.astrolog
    ];

    installPhase = ''
      mkdir -p $out/bin $out/share/astrolog-gui
      cp $src $out/share/astrolog-gui/astrolog-gui.py
      cat > $out/bin/astrolog-gui <<EOF
      #!${pkgs.bash}/bin/bash
      export PATH="${pkgs.astrolog}/bin:\$PATH"
      exec ${pythonEnv}/bin/python3 $out/share/astrolog-gui/astrolog-gui.py "\$@"
      EOF
      chmod +x $out/bin/astrolog-gui
    '';
  };
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
