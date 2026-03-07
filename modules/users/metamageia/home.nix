{
  config,
  pkgs,
  inputs,
  userValues,
  ...
}: {
  imports = [
    ../../alacritty
    ../../discord

    ../../zen
  ];

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };

    bash.enable = true;
  };

  # GTK theming
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };

  home.username = "metamageia";
  home.homeDirectory = "/home/metamageia";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    obsidian
    vscode
    qbittorrent
    libreoffice-qt

    scribus
    inkscape
    #krita
  ];

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
