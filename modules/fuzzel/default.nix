{
  config,
  pkgs,
  ...
}: {
  theming.wallust.templates.fuzzel = {
    source = ./wallust.tmpl;
    target = "${config.xdg.configHome}/fuzzel/fuzzel.ini";
  };

  home.packages = with pkgs; [
    fuzzel
  ];
}
