{
  config,
  pkgs,
  ...
}: {
  theming.wallust.templates.discord = {
    source = ./discord.tmpl;
    target = "${config.xdg.configHome}/vesktop/settings/quickCss.css";
  };

  theming.wallust.templates.vesktop-settings = {
    source = ./settings.tmpl;
    target = "${config.xdg.configHome}/vesktop/settings.json";
  };

  home.packages = with pkgs; [
    vesktop
  ];
}
