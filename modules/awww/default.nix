{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
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
      ExecStart = "${pkgs.awww}/bin/awww img '${userValues.wallpaper}' --transition-type center";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
