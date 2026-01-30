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

    # Starship prompt
    starship = {
      enable = true;
      settings = {
        format = "$directory$git_branch$git_status$character";
        character = {
          success_symbol = "[](bold #d4a017)";
          error_symbol = "[](bold #8b2252)";
        };
        directory = {
          style = "bold #9b59b6";
          format = "[ $path]($style) ";
        };
        git_branch = {
          style = "#6b8e9f";
        };
      };
    };
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
            "qwen2.5:7b" = {
              name = "Qwen 2.5 (7B) - Tool support";
              options = {
                temperature = 0.7;
                max_tokens = 512;
              };
            };
            "qwen2.5:3b" = {
              name = "Qwen 2.5 (3B) - Fast tool support";
              options = {
                temperature = 0.7;
                max_tokens = 512;
              };
            };
            "gemma3" = {
              name = "Gemma 3 (4B)";
              options = {
                temperature = 0.2;
                max_tokens = 240;
              };
            };
          };
        };
      };
    };
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
