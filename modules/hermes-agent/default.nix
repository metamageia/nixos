{
  inputs,
  pkgs,
  config,
  lib,
  userValues,
  ...
}: let
  espeakngLoader = pkgs.writeTextFile {
    name = "espeakng-loader-shim";
    destination = "/espeakng_loader/__init__.py";
    text = ''
      from pathlib import Path


      def get_library_path():
          return Path("${lib.getLib pkgs.espeak-ng}/lib/libespeak-ng.so")


      def get_data_path():
          return Path("${pkgs.espeak-ng}/share/espeak-ng-data")
    '';
  };

  kokoro-onnx = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "kokoro-onnx";
    version = "0.5.0";
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "kokoro_onnx";
      inherit version;
      sha256 = "0sn9g9c605rb24gamkidmc1p31dgg7095xwkskc8x0p2hpq1bssv";
    };

    build-system = [pkgs.python3.pkgs.hatchling];

    pythonRemoveDeps = ["phonemizer-fork" "espeakng-loader"];
    dependencies = with pkgs.python3.pkgs; [onnxruntime numpy phonemizer];
  };

  kokoroModel = pkgs.fetchurl {
    url = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx";
    sha256 = "1id66qvfzh2cfq44c8vpqcmvxvnh7w2qc9m32n08gcflyznghpbx";
  };
  kokoroVoices = pkgs.fetchurl {
    url = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin";
    sha256 = "0zdz3ygw5s8g2k4wml7y9qk7j5n0grz1kr3g5vrrk3cf62w119mw";
  };

  kokoroEnv = pkgs.python3.withPackages (ps:
    with ps; [
      numpy
      onnxruntime
      phonemizer
      soundfile
      kokoro-onnx
    ]);

  kokoro-tts = pkgs.writeShellScriptBin "kokoro-tts" ''
    export PYTHONPATH=${espeakngLoader}''${PYTHONPATH:+:$PYTHONPATH}
    exec ${kokoroEnv}/bin/python3 ${./kokoro-tts.py} \
      --model ${kokoroModel} --voices ${kokoroVoices} "$@"
  '';
in {
  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  users.groups.hermes = {};
  users.users.metamageia.extraGroups = ["hermes"];

  sops.secrets = {
    "hermes-auth" = {
      format = "json";
      sopsFile = "${userValues.secretsDir}/hermes-auth.json";
      key = "";
    };
    "hermes-discord" = {
      sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
    };
    "google-api" = {
      sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
      path = "/var/lib/hermes/.hermes/google_client_secret.json";
    };
    "tripo3d-api" = {
      sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
      path = "/var/lib/hermes/.hermes/tripo3d.key";
    };
  };

  sops.templates."hermes.env".content = ''
    DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-discord"}
    DISCORD_ALLOWED_USERS=663086185920331777
  '';

  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = ["/home/metamageia"];

  systemd.services.hermes-agent.serviceConfig.NoNewPrivileges = lib.mkForce false;
  systemd.services.hermes-agent.environment.HOME = lib.mkForce "/home/metamageia";

  systemd.services.hermes-agent.path = [
    kokoro-tts
    config.hardware.nvidia.package.bin
    "/run/current-system/sw"
  ];

  systemd.services.hermes-agent.environment.LD_LIBRARY_PATH = "${config.hardware.nvidia.package}/lib";

  systemd.services.hermes-agent.environment.DISCORD_HOME_CHANNEL = "1532688784796291164";
  systemd.services.hermes-agent.environment.DISCORD_DM_CHANNEL = "1532707219387187351";
  systemd.services.hermes-agent.environment.DISCORD_ALLOWED_USERS = "663086185920331777";
  systemd.services.hermes-agent.environment.HERMES_HOME_MODE = "2770";
  systemd.services.hermes-agent.environment.PONYTAIL_DEFAULT_MODE = "ultra";

  services.hermes-agent = {
    enable = true;
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.minimal;
    addToSystemPackages = true;

    user = "metamageia";
    createUser = false;

    extraDependencyGroups = ["messaging" "firecrawl"];

    # Seeded once; hermes refreshes the OAuth token in place afterward.
    authFile = config.sops.secrets."hermes-auth".path;

    environmentFiles = [config.sops.templates."hermes.env".path];

    settings = {
      terminal.cwd = "/home/metamageia";
      agent.api_max_retries = 10;

      model = {
        default = "~z-ai/glm-flash-latest";
        provider = "nous";
        base_url = "https://inference-api.nousresearch.com/v1";
      };
      fallback_providers = [];

      web = {
        backend = "firecrawl";
        use_gateway = true;
      };
      browser = {
        cloud_provider = "browser-use";
        use_gateway = true;
      };
      display = {
        show_reasoning = false;
        skin = "wallust";
        credits_notices = false;
      };
      tts = {
        provider = "kokoro";
        use_gateway = false;
        providers.kokoro = {
          type = "command";
          command = "kokoro-tts --text-file {input_path} --output {output_path} --voice {voice} --speed {speed}";
          output_format = "wav";
          voice = "af_bella";
          speed = 1.0;
        };
      };
      stt = {
        provider = "openai";
        use_gateway = true;
      };
      image_gen.use_gateway = true;
      platform_toolsets = {
        cli = ["hermes-cli" "video" "video_gen"];
        discord = ["hermes-discord" "video" "video_gen"];
      };
      approvals.destructive_slash_confirm = false;
      delegation.model = "~deepseek/deepseek-v4-flash-latest";
      delegation.max_spawn_depth = 1;

      cron.wrap_response = false;

      plugins.enabled = [
        "discord-webhook-bots"
        "ponytail"
      ];

      gateway.multiplex_profiles = true;

      gateway.profile_routes = [
        {
          name = "prosopon-project-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1540534948933664838";
          profile = "dev";
        }
        {
          name = "daw-project-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1540535194908500098";
          profile = "dev";
        }
        # Added 2026-08-23: JAVELIN project channel.
        {
          name = "project-javelin";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1541265265994760302";
          profile = "dev";
        }
      ];
      discord.require_mention = false;
      discord.auto_thread = false;
    };

    mcpServers = {
      robinhood-trading = {
        url = "https://agent.robinhood.com/mcp/trading";
        auth = "oauth";
      };
    };
  };
  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
  ];
}
