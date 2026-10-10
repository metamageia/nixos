{
  config,
  inputs,
  ...
}: let
  zenProfileDir = "e06yfgug.Default Profile";
in {
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  theming.wallust.templates.zen = {
    source = ./wallust.tmpl;
    target = "${config.xdg.configHome}/zen/${zenProfileDir}/chrome/userChrome.css";
  };

  programs.zen-browser = {
    enable = true;
    profiles.default = {
      name = "Default Profile";
      path = zenProfileDir;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "sine.allow-unsafe-js" = true;
        "zen.widget.linux.transparency" = true;
        "zen.urlbar.open-on-startup" = false;
      };
      sine = {
        enable = true;
        mods = [];
      };
    };
  };

  home.file."${config.xdg.configHome}/zen/${zenProfileDir}/chrome/sine-mods/mods.json".text = ''
    {
      "wallust-reloader": {
        "id": "wallust-reloader",
        "enabled": true,
        "origin": "local",
        "scripts": {
          "wallust-reloader.uc.js": {}
        }
      }
    }
  '';

  home.file."${config.xdg.configHome}/zen/${zenProfileDir}/chrome/sine-mods/wallust-reloader/wallust-reloader.uc.js".text = ''
    // ==UserScript==
    // @name         Wallust Zen theme reloader
    // @namespace    local.wallust
    // @description  Live-reload userChrome.css when wallust rewrites it.
    // @version      1.0
    // @include      *
    // ==/UserScript==
    (function () {
      "use strict";
      const file = Services.dirsvc.get("UChrm", Ci.nsIFile)
        .QueryInterface(Ci.nsIFile);
      file.append("userChrome.css");
      if (!file.exists() || !file.isFile()) return;
      let last = file.lastModifiedTime;
      const sss = Cc["@mozilla.org/content/style-sheet-service;1"]
        .getService(Ci.nsIStyleSheetService);
      setInterval(() => {
        try {
          const fresh = file.clone();
          if (fresh.exists() && fresh.lastModifiedTime > last) {
            last = fresh.lastModifiedTime;
            const uri = Services.io.newFileURI(fresh);
            [sss.USER_SHEET, sss.AGENT_SHEET].forEach((t) => {
              if (sss.sheetRegistered(uri, t)) sss.unregisterSheet(uri, t);
              sss.loadAndRegisterSheet(uri, t);
            });
            Services.obs.notifyObservers(null, "chrome-flush-caches", null);
          }
        } catch (e) { /* ignore */ }
      }, 1000);
    })();
  '';
}
