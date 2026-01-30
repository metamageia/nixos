{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 12;
          y = 12;
        };
        decorations = "none";
        opacity = 0.92;
      };
      font = {
        normal.family = "Iosevka Nerd Font";
        size = 12.0;
      };
      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
      };
    };
  };
}
