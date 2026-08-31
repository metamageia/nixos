{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Migrated 08-30 from a bare `home.packages` install to the flake's official
  # home-manager module (programs.zen-browser). This gives us declarative
  # profile management (userChrome/user.js/userContent/etc.) that the raw
  # package install lacked — the scaffolding for wallust-driven theming.
  #
  # The module installs the package itself (finalPackage -> home.packages), so
  # the old `home.packages = [ inputs.zen-browser.packages...default ]` line is
  # gone. The beta homeModule resolves the same beta build wrapped with
  # wrapFirefox + DisableAppUpdate/DisableTelemetry policies.
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;

    profiles = {
      # Adopts the EXISTING on-disk profile (~/.config/zen/e06yfgug.Default
      # Profile). The module regenerates profiles.ini from name + path; these
      # two values reproduce the pre-existing file exactly (Name=Default
      # Profile, Path=e06yfgug.Default Profile, Default=1), so no new/orphan
      # profile is spawned and all state/history/extensions are preserved.
      # `id = 0` is the module default and makes isDefault true. The attr key
      # is arbitrary (not baked into profiles.ini); name/path are what matter.
      default = {
        name = "Default Profile";
        path = "e06yfgug.Default Profile";

        # Enable custom, userChrome.css-driven chrome theming. NOTE: we leave
        # the module's own `userChrome` option EMPTY on purpose — wallust owns
        # chrome/userChrome.css via the wallust zen.tmpl template target. This
        # settings entry flips the pref (written to user.js) so Gecko loads the
        # wallust-written sheet. If we also set userChrome here, home-manager
        # would write its own chrome/userChrome.css and conflict with wallust.
        #
        # sine.allow-unsafe-js is REQUIRED to run a LOCAL (non-store) sine mod's
        # JS. Verified in Sine's utils.sys.mjs (getScripts): a mod's scripts only
        # execute if `sine.allow-unsafe-js` is true OR `mod.origin === "store"`.
        # Our wallust-reloader is declared by us (origin "local"), so we must
        # allow unsafe JS — this is the honest switch for running our own script.
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "sine.allow-unsafe-js" = true;
          # Transparent window surface on Linux/Wayland. The v2 zen.tmpl CSS makes
          # the whole chrome stack transparent, but that only reveals whatever the
          # WINDOW SURFACE is — and Gecko creates it opaque by default, so CSS alone
          # showed "fully solid" even with the root transparent. This is the official
          # Linux switch for browser-window (chrome) transparency — it makes Gecko
          # create the window as a transparent ARGB surface so the wallpaper shows
          # through the transparent chrome while the page region's opaque {{background}}
          # keeps the webpage solid. (NOTE: browser.tabs.allow_transparent_browser is
          # the DIFFERENT pref for making the webpage itself transparent — we do NOT
          # set it, since Gage wants the chrome transparent but the page opaque.)
          # Verified 08-30 against the official Transparent Zen mod + Linux guides.
          "zen.widget.linux.transparency" = true;
        };

        # sine.enable with EMPTY mods installs ONLY the loader (chrome/utils +
        # chrome/JS bootloader) with no store mods fetched — the flake's native
        # way to get the bootloader that scans chrome/sine-mods/mods.json and
        # runs enabled mods. Our watcher is registered as a LOCAL mod in
        # chrome/sine-mods/mods.json (see home.file below), NOT via the store.
        sine = {
          enable = true;
          mods = [];
        };
      };
    };
  };

  # The live-reload watcher, as a LOCAL sine mod.
  #
  # Ground truth (verified 08-30 from Sine source + bootloader chrome.manifest):
  # the bootloader maps `chrome://sine` → chrome/sine-mods/, and Sine's manager
  # loads each enabled mod's registered `.uc.js` scripts from
  # chrome/sine-mods/<modId>/<file>.uc.js. The mod is registered in mods.json as
  # { "<id>": { enabled, origin, scripts: { "<file>.uc.js": {} } } }.
  #
  # NOTE: this is the fix for step 3 — the old version placed the script in
  # chrome/JS/wallust-reloader.uc.js unregistered, which Sine never ran (it only
  # runs SCRIPTS REGISTERED in mods.json, not stray files). Registering it here
  # as a mod makes Sine actually execute it.

  # The mod declaration that sine reads.
  home.file."${config.xdg.configHome}/zen/e06yfgug.Default Profile/chrome/sine-mods/mods.json".text = ''
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

  # The watcher script itself, in the mod's folder (resolves under chrome://sine).
  # Polls userChrome.css's mtime each second; when wallust rewrites it,
  # re-registers the sheet through the style-sheet service and flushes caches —
  # the running browser recolors without restarting.
  home.file."${config.xdg.configHome}/zen/e06yfgug.Default Profile/chrome/sine-mods/wallust-reloader/wallust-reloader.uc.js".text = ''
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