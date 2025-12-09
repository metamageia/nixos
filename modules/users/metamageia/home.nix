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

  home.username = "metamageia";
  home.homeDirectory = "/home/metamageia";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "23.11";

  home.packages = with pkgs; [
    obsidian
    vscode
    qbittorrent
    libreoffice-qt
    docling

    scribus
    inkscape
    krita
  ];

  home.file = {
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
