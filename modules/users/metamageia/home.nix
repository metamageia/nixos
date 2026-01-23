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
    #docling

    scribus
    inkscape
    krita
  ];

  home.file = {
    ".config/opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options = {
            baseURL = "http://127.0.0.1:11434/v1";
          };
          models = {
            "gemma3" = { name = "Gemma 3 (4B)"; options = { temperature = 0.2; max_tokens = 240; }; };
          };
        };
      };
    };
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
