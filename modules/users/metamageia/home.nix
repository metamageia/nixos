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

  # Hermes profile command aliases (aisling, new-daimon, future daimons) install
  # to $HOME/.local/bin; put that dir on the session PATH so the bare commands
  # resolve. Applies at the next home-manager switch / nixos-rebuild.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Convenience handle on the gateway-managed SOUL.md, which hermes rewrites
  # at runtime — an out-of-store symlink keeps it mutable.
  home.file.".hermes/SOUL.md".source =
    config.lib.file.mkOutOfStoreSymlink "/var/lib/hermes/.hermes/SOUL.md";

  programs.home-manager.enable = true;
}
