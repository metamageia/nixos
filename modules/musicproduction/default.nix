{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  jsReaLibs = with pkgs; [gtk3 stdenv.cc.cc.lib];

  # daw — bespoke Rust/egui DAW (Live 12 arrangement clone), built from the
  # ~/Development/daw repo (flake input `daw`). Matches its devShell's
  # runtime env: LV2_PATH is already set globally to /run/current-system/sw/lib/lv2
  # (system plugins incl. mda/x42), so only GM_SOUNDFONT needs wrapping here.
  # DISABLED: path input missing on setseke; re-enable input in flake.nix + this block.
  # daw = pkgs.rustPlatform.buildRustPackage {
  #   pname = "daw";
  #   version = "0.1.0";
  #   src = inputs.daw;
  #   cargoLock.lockFile = "${inputs.daw}/Cargo.lock";
  #
  #   nativeBuildInputs = with pkgs; [pkg-config makeWrapper];
  #   buildInputs = with pkgs; [
  #     wayland
  #     libxkbcommon
  #     libGL
  #     alsa-lib
  #     lilv
  #     lv2
  #     serd
  #     sord
  #     sratom
  #   ];
  #
  #   postInstall = ''
  #     wrapProgram $out/bin/daw \
  #       --set GM_SOUNDFONT "${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2"
  #     mkdir -p $out/share/applications
  #     cat > $out/share/applications/daw.desktop <<EOF
  # [Desktop Entry]
  # Type=Application
  # Name=DAW
  # Comment=Bespoke Live 12 arrangement-view clone
  # Exec=daw
  # Terminal=false
  # Categories=AudioVideo;Audio;
  # EOF
  #   '';
  #
  #   meta = with lib; {
  #     description = "Bespoke single-window DAW cloning Ableton Live 12 arrangement view";
  #     license = licenses.mit;
  #     platforms = ["x86_64-linux"];
  #   };
  # };

  soundthread = pkgs.stdenv.mkDerivation rec {
    pname = "soundthread";
    version = "0.4.0-beta";

    src = pkgs.fetchurl {
      url = "https://github.com/j-p-higgins/SoundThread/releases/download/v${version}/SoundThread_v0-4-0-beta_linux_x86_64.tar.gz";
      sha256 = "028z3g4sqrg8qif82ap3cc0xxrq6nkvv0ipmp8b17564alqnk6b8";
    };

    nativeBuildInputs = with pkgs; [autoPatchelfHook makeWrapper];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      libGL
      libxkbcommon
      alsa-lib
      pulseaudio
       libX11
       libXcursor
       libXi
       libXrandr
       libXrender
       libXext
       libXfixes
      fontconfig
      freetype
      dbus
      udev
      wayland
    ];

    runtimeLibs = with pkgs; [
      libGL
      libxkbcommon
      alsa-lib
      pulseaudio
      pipewire
       libX11
       libXcursor
       libXi
       libXrandr
       libXrender
       libXext
       libXfixes
      wayland
      libdecor
      dbus
      fontconfig
      freetype
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/soundthread $out/bin

      install -m755 SoundThread.x86_64 $out/share/soundthread/SoundThread.x86_64
      tar xzf cdprogs_linux.tar.gz -C $out/share/soundthread/

      makeWrapper $out/share/soundthread/SoundThread.x86_64 $out/bin/SoundThread \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

      mkdir -p $out/share/applications
      cat > $out/share/applications/soundthread.desktop <<EOF
[Desktop Entry]
Type=Application
Name=SoundThread
Comment=GUI for the Composers Desktop Project sound manipulation suite
Exec=SoundThread
Terminal=false
Categories=AudioVideo;Audio;
EOF

      runHook postInstall
    '';

    meta = with lib; {
      description = "Cross-platform GUI for the Composers Desktop Project (CDP) sound manipulation suite";
      homepage = "https://github.com/j-p-higgins/SoundThread";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
    };
  };

  reaper-js-reascript-api = pkgs.stdenv.mkDerivation rec {
    pname = "reaper-js-reascript-api";
    version = "1.310.101";

    src = pkgs.fetchurl {
      url = "https://github.com/juliansader/js_ReaScriptAPI/releases/download/${version}/reaper_js_ReaScriptAPI64.so";
      sha256 = "1bj9byx2wryh5730h3caqpnhb6gsh30vxnirx8ndizmwbrhgs1jv";
    };

    dontUnpack = true;
    nativeBuildInputs = [pkgs.patchelf];
    buildInputs = jsReaLibs;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/UserPlugins
      install -m644 $src $out/UserPlugins/reaper_js_ReaScriptAPI64.so
      patchelf --set-rpath "${lib.makeLibraryPath jsReaLibs}" \
        $out/UserPlugins/reaper_js_ReaScriptAPI64.so
      runHook postInstall
    '';

    meta = with lib; {
      description = "js_ReaScriptAPI extension for REAPER (Linux x86_64 prebuilt)";
      homepage = "https://github.com/juliansader/js_ReaScriptAPI";
      license = licenses.lgpl21Plus;
      platforms = ["x86_64-linux"];
    };
  };
in {
  environment.variables = {
    LV2_PATH = "/run/current-system/sw/lib/lv2";
  };

  home-manager.users.metamageia.home.file = {
    ".config/REAPER/UserPlugins/reaper_sws-x86_64.so".source = "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so";
    ".config/REAPER/UserPlugins/reaper_reapack-x86_64.so".source = "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so";
    ".config/REAPER/UserPlugins/reaper_js_ReaScriptAPI64.so".source = "${reaper-js-reascript-api}/UserPlugins/reaper_js_ReaScriptAPI64.so";
    ".local/share/soundthread/cdprogs_linux".source = "${soundthread}/share/soundthread/cdprogs_linux";
  };

  environment.systemPackages = with pkgs; [
    # Daw
    reaper
    # daw  # disabled: path input missing on setseke
    # ardour
    #lmms

    # Plugins
    distrho-ports
    yabridge
    yabridgectl
    bespokesynth
    rkrlv2
    mda_lv2
    x42-plugins
    carla
     soundfont-generaluser-gs
    infamousPlugins
    talentedhack
    lsp-plugins
    drum-machine
    x42-avldrums
    bitwig-studio

    # Sound design / experimental
    soundthread
  ];
}
