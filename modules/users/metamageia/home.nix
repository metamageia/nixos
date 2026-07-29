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
    ../../awww
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
  ];

  home.sessionVariables = {
  };

  # Convenience handle on the gateway-managed SOUL.md, which hermes rewrites
  # at runtime — an out-of-store symlink keeps it mutable.
  home.file.".hermes/SOUL.md".source =
    config.lib.file.mkOutOfStoreSymlink "/var/lib/hermes/.hermes/SOUL.md";

  programs.home-manager.enable = true;
}
