{
  config,
  pkgs,
  ...
}: {
  theming.wallust.templates.hermes = {
    source = ./skin.tmpl;
    target = "${config.xdg.configHome}/wallust/hermes-skin.yaml";
  };

  systemd.user.services.hermes-desktop-skin-boot = {
    Unit = {
      Description = "Apply wallust skin to the Hermes desktop at launch";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = toString (pkgs.writeShellScript "hermes-desktop-skin-boot" ''
        skins_dir="$(${config.home.path}/bin/hermes-skins-dir)"
        SKIN="$skins_dir/wallust.yaml"
        last=""
        while true; do
          pid=$("${pkgs.procps}/bin/pgrep" -f 'share/hermes-desktop' | "${pkgs.coreutils}/bin/head" -n1 || true)
          if [ -n "$pid" ] && [ "$pid" != "$last" ]; then
            last="$pid"
            for d in 2 4 4; do "${pkgs.coreutils}/bin/sleep" "$d"; "${pkgs.coreutils}/bin/touch" "$SKIN"; done
          fi
          "${pkgs.coreutils}/bin/sleep" 2
        done
      '');
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
