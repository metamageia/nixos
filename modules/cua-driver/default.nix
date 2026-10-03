{ pkgs, ... }:
let
  version = "0.28.2";
  cua-driver = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "cua-driver";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v${finalAttrs.version}/cua-driver-rs-${finalAttrs.version}-linux-x86_64-binary.tar.gz";
      hash = "sha256-odmf0Eu0kn71/9vmDrke2LUaK6tg4Q/GBKdb1ZzmnD4=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.libX11 pkgs.libXi pkgs.libxkbcommon pkgs.stdenv.cc.cc.lib ];

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      install -Dm755 cua-driver $out/bin/cua-driver
    '';
  });
in {
  environment.systemPackages = [ cua-driver ];
}
