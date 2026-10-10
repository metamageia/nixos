{pkgs, ...}: {
  theming.wallust.templates.obsidian = {
    source = ./wallust.tmpl;
    target = "/home/metamageia/Sync/Obsidian/.obsidian/snippets/wallust.css";
  };

  home.packages = with pkgs; [
    obsidian
  ];
}
