{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  home.packages = with pkgs; [swww];

  systemd.user.services.swww = {
    Unit = {
      Description = "Start swww daemon";
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.swww}/bin/swww-daemon --format xrgb";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.services.swww-wallpaper = {
    Unit = {
      Description = "Set initial wallpaper using swww";
      After = ["swww.service"];
      Wants = ["swww.service"];
    };
    Service = {
      ExecStart = "${pkgs.swww}/bin/swww img '${userValues.wallpaper}' --transition-type center";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
