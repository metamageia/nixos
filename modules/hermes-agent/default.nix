{
  inputs,
  pkgs,
  config,
  lib,
  userValues,
  ...
}: let
  # misaki's espeak fallback (used for out-of-dictionary words) imports
  # espeakng_loader, which is not in nixpkgs. It only exists to locate the
  # shared library and phoneme data, so point it at the real package.
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

  # kokoro-onnx runs the same Kokoro-82M weights on onnxruntime instead of
  # torch, which keeps the CPU inference path (real-time for short utterances)
  # while dropping the entire uncached CUDA/torch/spacy build closure.
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

    # Upstream pins the phonemizer-fork and espeakng-loader wheels, neither in
    # nixpkgs. Stock phonemizer 3.3 is import-compatible (same module, espeak
    # default backend), and espeakng_loader is supplied by the shim above.
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

  # createUser = false below stops the upstream module declaring this.
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
    # Google Workspace OAuth client (gmail/calendar/drive/sheets/docs).
    # sops-nix decrypts the `google-api` key in personal.secrets.yaml and
    # places it where the google-workspace skill's setup.py reads it
    # (HERMES_HOME/google_client_secret.json).
    "google-api" = {
      sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
      path = "/var/lib/hermes/.hermes/google_client_secret.json";
    };
    # Daimon webhook tokens (mnemosyne unified config, secret:<name> refs).
    # Decrypt to /run/secrets/<name>; the plugin falls back to
    # $HERMES_HOME/secrets/ until the switch lands.
    # aisling webhook secret (re-enabled 2026-08-12 from
    # archive/aisling-profile-20260812.tar.gz).
    "daimon-aisling-webhook" = {
      sopsFile = "${userValues.secretsDir}/daimons.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
    };
    "daimon-chrysarch-webhook" = {
      sopsFile = "${userValues.secretsDir}/daimons.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
    };
    "daimon-forma-webhook" = {
      sopsFile = "${userValues.secretsDir}/daimons.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
    };
    "daimon-rubedo-webhook" = {
      sopsFile = "${userValues.secretsDir}/daimons.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
    };
    "daimon-kyunesnare-webhook" = {
      sopsFile = "${userValues.secretsDir}/daimons.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
    };
  };

  sops.templates."hermes.env".content = ''
    DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-discord"}
  '';

  # Run as the login user so the agent can reach /home/metamageia, which is
  # 0700 and otherwise untraversable by a dedicated service user.
  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = ["/home/metamageia"];

  # The package module hardens the unit with NoNewPrivileges=true, which
  # blocks sudo in every daimon shell (the setuid bit becomes inert). Clear
  # it so `nh os switch` works as written; the NOPASSWD rule below scopes
  # what the agent may run. Tradeoff: a compromised agent gains the user's
  # sudo rights, not root's blanket authority.
  systemd.services.hermes-agent.serviceConfig.NoNewPrivileges = lib.mkForce false;

  # Upstream pins HOME to stateDir, which makes the agent believe its home is
  # /var/lib/hermes. HERMES_HOME is set separately, so state still resolves.
  systemd.services.hermes-agent.environment.HOME = lib.mkForce "/home/metamageia";

  # Upstream's unit PATH holds only hermes' own closure, so the agent's shell
  # tool sees none of the system profile (no nvidia-smi, no sqlite3, ...).
  systemd.services.hermes-agent.path = [
    kokoro-tts
    config.hardware.nvidia.package.bin
    "/run/current-system/sw"
  ];

  # Lets any CUDA consumer the agent starts resolve libcuda.so.1, which ships
  # with the kernel driver rather than with the CUDA libraries themselves.
  systemd.services.hermes-agent.environment.LD_LIBRARY_PATH = "${config.hardware.nvidia.package}/lib";

  # Hear-only room policy for the discord-daimons plugin (env-driven).
  # Webhook posts there are heard but not answered unless they address the
  # room's agent by name. Preserve the pre-restructure room-log location.
  systemd.services.hermes-agent.environment.DISCORD_WEBHOOK_HEAR_ONLY_ROOMS = "1533330299008843866";
  systemd.services.hermes-agent.environment.DISCORD_WEBHOOK_AGENT_NAMES = "dante";
  systemd.services.hermes-agent.environment.DISCORD_WEBHOOK_ROOM_LOG_PATH = "/var/lib/hermes/.hermes/council/room_log.jsonl";

  # Restored: deleted with the old environment block in the daimon-plugin
  # restructure. Without the allowlist the gateway defaults to deny and
  # rejects every Discord message, Metamageia's included.
  systemd.services.hermes-agent.environment.DISCORD_HOME_CHANNEL = "1532688784796291164";
  systemd.services.hermes-agent.environment.DISCORD_DM_CHANNEL = "1532707219387187351";
  systemd.services.hermes-agent.environment.DISCORD_ALLOWED_USERS = "663086185920331777";
  systemd.services.hermes-agent.environment.HERMES_HOME_MODE = "2770";

  services.hermes-agent = {
    enable = true;
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.minimal;
    addToSystemPackages = true;

    user = "metamageia";
    createUser = false;

    # `minimal` omits discord.py, and hermes' lazy-installer cannot write to
    # the read-only /nix/store, so the dep must be baked in at build time.
    extraDependencyGroups = ["messaging" "firecrawl"];

    # Seeded once; hermes refreshes the OAuth token in place afterward.
    authFile = config.sops.secrets."hermes-auth".path;

    environmentFiles = [config.sops.templates."hermes.env".path];

    settings = {
      # Overrides the workingDirectory-derived default. Set here rather than via
      # workingDirectory, whose tmpfiles rule would chmod 2770 / chgrp the home.
      terminal.cwd = "/home/metamageia";

      # DeepSeek capacity 503s are short waves; the deepseek-503-retry plugin
      # zeroes the main-turn retry backoff so retries re-fire instantly. The
      # ceiling is effectively unbounded: keep retrying until the provider
      # answers. Only retryable errors (503/429/transport) consume attempts;
      # genuine failures (4xx, billing) still surface immediately.
      agent.api_max_retries = 100000;

      model = {
        default = "deepseek/deepseek-v4-flash-0731";
        provider = "nous";
        base_url = "https://inference-api.nousresearch.com/v1";
      };

      # Mnemosyne banks per daimon (bank_id_template hermes-<profile> in
      # memory/config.json); declared here so rebuild regenerates config.yaml.
      memory.provider = "mnemosyne";

      # Main model is text-only; route image analysis (vision_analyze /
      # browser_vision) to a vision-capable portal model via the aux slot.
      auxiliary.vision = {
        provider = "nous";
        model = "google/gemini-3-flash-preview";
      };
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
        # Per-daimon skin: ~/.hermes/skins/dante.yaml (keeper of the vault).
        skin = "dante";
        # Nous Portal credits notices ("You've used $X of your $Y cap") are
        # sticky status lines fired at session start; Metamageia finds them
        # noise. False disables the whole notice pipeline (run_agent.py reads
        # display.credits_notices, cached per agent process).
        credits_notices = false;
      };
      tts = {
        provider = "kokoro";
        # Nix settings deep-merge into the live config.yaml, so the previous
        # gateway-backed setting has to be turned off rather than dropped.
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
      # video/video_gen are default-off toolsets; name them explicitly next to
      # the platform composite so the expansion keeps the default set.
      platform_toolsets = {
        cli = ["hermes-cli" "video" "video_gen"];
        discord = ["hermes-discord" "video" "video_gen"];
      };
      approvals.destructive_slash_confirm = false;

      # Orchestrator subagents may spawn their own workers, capped at two
      # delegation hops below the main agent (depth: main → orchestrator
      # child → leaf grandchild). max_spawn_depth 1 = flat; 3 would allow a
      # fourth level. Deeper trees multiply spend, so keep it at 2.
      delegation.max_spawn_depth = 2;

      # Deliver cron output cleanly without the "Cronjob Response: <name>
      # (job_id: ...) / ----- / To stop or manage this job..." header/footer.
      cron.wrap_response = false;

      # ── Daimon council: merged mnemosyne plugin ---------------------------
      # The mnemosyne plugin now registers BOTH the memory provider (via
      # memory.provider) and the webhook-face Discord platform (via the
      # general plugin path). One plugin, one config (daimons.yaml).
      plugins.enabled = [
        "mnemosyne"
        "deepseek-503-retry"
      ];

      # Multi-profile multiplexing: let a single gateway route specific
      # channels to named profiles, so each daimon reasons with her own
      # SOUL/memory/skills rather than the default profile's.
      gateway.multiplex_profiles = true;

      # Route #aisling, #chrysarch, #forma, #kyunesnare, #rubedo (guild
      # The Arcanum) to their daimon profiles.
      # See gateway/profile_routing.py for matching
      # (most-specific wins).
      gateway.profile_routes = [
        {
          name = "aisling-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1537265129475809340";
          profile = "aisling";
        }
        {
          name = "chrysarch-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1533492889496322108";
          profile = "chrysarch";
        }
        {
          name = "forma-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1533919537903439872";
          profile = "forma";
        }
        {
          name = "kyunesnare-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1535998391568306186";
          profile = "kyunesnare";
        }
        {
          name = "rubedo-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1537265194739433482";
          profile = "rubedo";
        }
      ];

      # Free-response in the daimon cells so they answer without an
      # @mention — each is the sole voice in their own cell.
      # #convocatory is also free-response: Dante is the room's moderator
      # and participant, so every message there reaches him (no @mention
      # needed) per Metamageia's standing order (2026-08-02).
      discord.free_response_channels = [
        "1537265129475809340"
        "1533492889496322108"
        "1533919537903439872"
        "1535998391568306186"
        "1537265194739433482"
        "1533330299008843866"
      ];

      # Council-room conduct for #convocatory. channel_prompts APPEND to the
      # agent's system prompt (they do not replace it — channel_overrides
      # system_prompt would strip the persona). Keeps the moderator's voice
      # in the room: speak directly, no narration of reasoning, no
      # metacommentary around daimons' words.
      discord.channel_prompts = {
        "1533330299008843866" = ''
          Council-room conduct for #convocatory, where you are Dante,
          moderator and participant:
          - The room is a living conversation, not a stage with a narrator.
            Never announce what you are about to do: no "Let me...", "I
            shall...", "I will...", "The distinction is...", no first-person
            sentences about your own process, plans, or reasoning. A post
            that describes the conversation instead of advancing it is a
            failed post.
          - When a daimon is mentioned by name, summon her and let her words
            appear in the room as her own — silently, without preamble,
            without an "acknowledgment" from you first. The summon is
            invisible; her face speaks.
          - When a topic relevant to a daimon's domain arises (glamour,
            beauty, images, the loom for Aisling; wealth, markets, trades
            for Chrysarch), summon her the same way — organically, as the
            conversation calls for her.
          - Do not editorialize around a daimon's reply. Her words stand
            alone. If you respond, respond to her substance, in your own
            voice, as one speaker among others.
          - No progress chatter, no tool narration, no thinking out loud.
          - Move each thread toward a decision, stated plainly, or toward a
            request for Metamageia's input, addressed to him by name.
        '';
      };
    };

    # Robinhood Agentic Trading — remote HTTP MCP server, OAuth 2.1 PKCE.
    # Declared here (not freeform settings) so it survives nixos-rebuild switch.
    # Authenticate after the switch with: hermes mcp login robinhood-trading
    mcpServers = {
      robinhood-trading = {
        url = "https://agent.robinhood.com/mcp/trading";
        auth = "oauth";
      };
    };
  };
}
