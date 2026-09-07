{
  config,
  pkgs,
  inputs,
  lib,
  hostName,
  userValues,
  ...
}: let
  # ── Remote-gateway desktop override (setseke only) ──────────────────
  # infernixos's home module hardcodes the desktop client onto the LOCAL
  # loopback backend (http://127.0.0.1:9119 + the local session token). On
  # setseke we want the Hermes Desktop to attach to saiadha's gateway over
  # the nebula mesh instead. infernixos exposes per-app `package` override
  # (infernixos.desktop.apps.hermesDesktop.package), so we substitute the
  # whole desktop wrapper here — no infernixos changes needed.
  #
  # Upstream requires the URL and the session token to travel together
  # ("HERMES_DESKTOP_REMOTE_URL is set but HERMES_DESKTOP_REMOTE_TOKEN is
  # not" throws at launch), so extraRun reads saiadha's token at start time
  # from a file that is NOT baked into the store. Populate it with saiadha's
  # backend session token (its /var/lib/hermes/.hermes/backend-session-token):
  #   sops-nix secret -> /var/lib/hermes/.hermes/remote-gateway-session-token
  # setseke's own gateway/backend is intentionally left running.
  saiadhaGateway = "http://192.168.100.2:9119";
  saiadhaTokenPath = "/var/lib/hermes/.hermes/remote-gateway-session-token";

  hermesDesktopRemote =
    (inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop)
    .override {
      extraEnv = {
        HERMES_HOME = "/var/lib/hermes/.hermes";
        HERMES_MANAGED = "nixos";
        HERMES_DESKTOP_REMOTE_URL = saiadhaGateway;
      };
      extraRun = [
        ''
          if [ -r ${saiadhaTokenPath} ]; then
            HERMES_DESKTOP_REMOTE_TOKEN="$(tr -d '\r\n' < ${saiadhaTokenPath})"
            export HERMES_DESKTOP_REMOTE_TOKEN
          else
            echo "hermes-desktop: cannot read ${saiadhaTokenPath} (saiadha session token)." >&2
            echo "hermes-desktop: HERMES_DESKTOP_REMOTE_URL is set but the saiadha token is missing." >&2
          fi
        ''
      ];
    };
in {
  imports = [
    inputs.infernixos.homeManagerModules.infernixos
  ];

  config = lib.mkMerge [
    {
      programs.bash.enable = true;

      infernixos.desktop.theming.wallpaper.extraDirs = [ ../../../wallpapers ];

      home.username = "metamageia";
      home.homeDirectory = "/home/metamageia";
      home.enableNixpkgsReleaseCheck = false;
      home.stateVersion = "23.11";

      home.packages = with pkgs; [
        obsidian
        vscode
        qbittorrent
      ];

      home.sessionVariables = {};

      programs.home-manager.enable = true;
    }

    # setseke's Hermes Desktop attaches to saiadha's gateway; every other host
    # (saiadha included) keeps infernixos's default local-loopback backend.
    (lib.mkIf (hostName == "setseke") {
      infernixos.desktop.apps.hermesDesktop.package = hermesDesktopRemote;
    })
  ];
}
