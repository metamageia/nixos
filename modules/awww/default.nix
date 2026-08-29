{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: let
  # State file recording the last wallpaper chosen via wallust-switch. Read by the
  # awww-wallpaper service at session start so a rebuild/login restores the last
  # choice instead of resetting to the hardcoded default.
  wallustStateFile = "${config.xdg.configHome}/wallust/last-wallpaper";
in {
  home.packages = with pkgs; [awww];

  systemd.user.services.awww = {
    Unit = {
      Description = "Start awww daemon";
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon --format xrgb";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.services.awww-wallpaper = {
    Unit = {
      Description = "Set initial wallpaper using awww";
      After = ["awww.service"];
      Wants = ["awww.service"];
    };
    Service = {
      # Restore the last wallpaper chosen via wallust-switch (state file) if it
      # exists, else fall back to the declared default. This stops a rebuild/login
      # from resetting the wallpaper to the hardcoded default.
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ -f \"${wallustStateFile}\" ]; then ${pkgs.awww}/bin/awww img \"$(cat \"${wallustStateFile}\")\" --transition-type center; else ${pkgs.awww}/bin/awww img \"${userValues.wallpaper}\" --transition-type center; fi'";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
