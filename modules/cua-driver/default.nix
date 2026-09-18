# cua-driver — upstream prebuilt Rust binary (GitHub releases only; not in
# nixpkgs, and cua.ai doesn't resolve from this box). The release tarball is a
# generic-linux dynamically linked binary, so autoPatchelfHook + the three
# missing X libs is what makes it runnable on NixOS (verified: `cua-driver
# --version` -> 0.28.2, "0 dependencies could not be satisfied").
#
# Bump: change `version`, then `nix store prefetch-file --hash-type sha256
# <the new tarball url>` for the hash.
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
  # On PATH for the hermes-agent service too (its unit PATH includes
  # /run/current-system/sw/bin), so no HERMES_CUA_DRIVER_CMD override needed.
  environment.systemPackages = [ cua-driver ];
}
