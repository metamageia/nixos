{ config, pkgs, lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      qt5 = prev.qt5.overrideScope' (final': prev': {
        qtModule = prev'.qtModule.overrideAttrs (old: {
          src = pkgs.fetchurl {
            url = "https://download.qt.io/official_releases/qt/5.15/5.15.12/single/qt-everywhere-src-5.15.12.tar.xz";
            sha256 = "<your-sha256-here>";
          };
          version = "5.15.12";
        });
        qtbase = prev'.qtbase.overrideAttrs (old: {
          src = pkgs.fetchurl {
            url = "https://download.qt.io/official_releases/qt/5.15/5.15.12/single/qt-everywhere-src-5.15.12.tar.xz";
            sha256 = "<same-sha256>";
          };
          version = "5.15.12";
        });
      });
    })
  ];

  environment.systemPackages = [ pkgs.scribus ];
}
