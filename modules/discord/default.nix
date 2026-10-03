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
