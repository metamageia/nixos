{
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
  ];
  home.packages = with pkgs; [
    vesktop
  ];

  # Alias Vesktop as "Discord" in fuzzel/launchers. The vesktop package ships a
  # desktop entry named "Vesktop" (Name=Vesktop); Gage wants it listed as
  # "Discord" (08-30). XDG desktop-entry resolution gives ~/.local/share/
  # applications (XDG_DATA_HOME) priority over the profile dir, so:
  #   - discord.desktop shadows nothing (new entry) and launches vesktop.
  #   - vesktop.desktop re-declares the same filename with NoDisplay=true to
  #     hide the profile's "Vesktop" entry, leaving only "Discord".
  xdg.desktopEntries = {
    discord = {
      name = "Discord";
      genericName = "Internet Messenger";
      comment = "Vesktop — Discord client";
      exec = "vesktop %U";
      icon = "vesktop";
      categories = [ "Network" "InstantMessaging" "Chat" ];
      mimeType = [ "x-scheme-handler/discord" ];
      terminal = false;
    };
    vesktop = {
      name = "Vesktop";
      exec = "vesktop %U";
      icon = "vesktop";
      terminal = false;
      noDisplay = true;
    };
  };

  # Vesktop owns two settings files, both rewritten at runtime, so home-manager
  # can't own them with a plain home.file (would be clobbered). Two stores:
  #
  #   1. ~/.config/vesktop/settings.json -> Vesktop's OWN settings
  #      (VesktopSettings store; src/main/settings.ts reads DATA_DIR/settings.json)
  #      enableSplashScreen:false + splashBackground:{{background}} are rendered
  #      by wallust's vesktop-settings.tmpl (see modules/wallust), so wallust
  #      owns this file — the module must NOT also write it.
  #   2. ~/.config/vesktop/settings/settings.json -> Vencord settings
  #      (VencordSettings store; VENCORD_SETTINGS_FILE)
  #      - useQuickCss: keep Vencord's Quick CSS applied (wallust theme rides it).
  #
  # The Vencord file is the one we ensure here. useQuickCss must stay true or the
  # wallust theme (quickCss.css) won't load. Idempotent: only sets our keys.
  home.activation.ensureVesktopSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ensure_vesktop_settings() {
      ${pkgs.python3}/bin/python3 - <<PY
import json, pathlib

# Vencord settings — useQuickCss lives HERE (wallust owns the Vesktop file).
vencord = pathlib.Path("$HOME/.config/vesktop/settings/settings.json")
if vencord.is_file():
    d = json.loads(vencord.read_text())
    d.setdefault("useQuickCss", True)
    vencord.write_text(json.dumps(d, indent=4))
PY
    }
    ensure_vesktop_settings
  '';
}
