{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    services.localOllama = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable local Ollama server service";
      };

      defaultModel = lib.mkOption {
        type = lib.types.str;
        # Gemma 3 (4B) is a conversational, low-latency model better suited
        # for persona/companion use on modest hardware than the 8B Llama model.
        default = "gemma3";
        description = "Model Ollama should pull automatically (one-shot at boot)";
      };
    };
  };

  config = lib.mkIf config.services.localOllama.enable {
    services.ollama = {
      enable = true;
      host = "127.0.0.1";
      port = 11434;
    };

    environment.systemPackages = [pkgs.ollama];

    # One-shot service to pull a model once ollama is up
    systemd.services.ollama-pull-default-model = {
      description = "Pull default Ollama model";
      wants = ["ollama.service"];
      after = ["ollama.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.ollama}/bin/ollama pull ${config.services.localOllama.defaultModel}";
        User = "ollama";
        Group = "ollama";
        Environment = [
          "HOME=/var/lib/ollama"
          "OLLAMA_HOST=127.0.0.1:11434"
        ];
      };
      wantedBy = ["multi-user.target"];
    };
  };
}
