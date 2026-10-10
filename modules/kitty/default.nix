{
  config,
  pkgs,
  ...
}: {
  theming.wallust.templates.kitty = {
    source = ./wallust.tmpl;
    target = "${config.xdg.configHome}/kitty/kitty.conf";
  };

  home.packages = with pkgs; [
    kitty
  ];
}
