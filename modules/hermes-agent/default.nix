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
    # Tripo3D API key (text/image-to-3D service). Decrypt to a stable path
    # agents read directly; ~/.secrets/tripo3d.key is the interim copy until
    # this lands via rebuild.
    "tripo3d-api" = {
      sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
      owner = "metamageia";
      group = "hermes";
      mode = "0440";
      path = "/var/lib/hermes/.hermes/tripo3d.key";
    };
    # Daimon webhook tokens (daimon-webhook-plugin, secret:<name> refs).
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

      # DeepSeek fallback machinery removed 08-25 (deepseek-503-retry plugin
      # disabled + fallback_providers emptied). Default retry ceiling restored:
      # genuine failures surface immediately instead of retrying forever.
      agent.api_max_retries = 10;

      model = {
        # Top-level profile runs DeepSeek v4 Flash (latest alias, ~1.3M ctx)
        # as of 09-01. The 0731 snapshot is pinned to a 163k window by the
        # provider; the latest alias resolves to a 1M+ context.
        default = "~deepseek/deepseek-v4-flash-latest";
        provider = "nous";
        base_url = "https://inference-api.nousresearch.com/v1";
      };

      # Explicitly empty: live config.yaml had a deepseek fallback entry here;
      # nix deep-merge would keep it unless overridden. No failover wanted —
      # failures surface directly.
      fallback_providers = [];

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
        # Active skin = `wallust`, the file wallust renders to
        # /var/lib/hermes/.hermes/skins/wallust.yaml on every Mod+W. The
        # gateway's skin watcher polls (name, mtime) and broadcasts
        # skin.changed; wallust-apply bumps the name field to the wallpaper
        # basename so the desktop's name-based apply guard repaints live.
        skin = "wallust";
        # Per-daimon skin is set in each daimon's own profile config
        # (dante's skin lives at profiles/dante/config.yaml).
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

      # Subagent delegation model: Tencent Hy3 (295B MoE) for delegated
      # workers. Free via Nous Portal (tencent/hy3:free) for a two-week
      # window starting 08-27; re-assess when the window closes. The main
      # model stays deepseek-v4-flash-0731.
      delegation.model = "tencent/hy3:free";
      # Flat delegation: orchestrator children cannot spawn their own
      # workers (1 = main → leaf only). Chosen 08-27 to cap spend.
      delegation.max_spawn_depth = 1;

      # Deliver cron output cleanly without the "Cronjob Response: <name>
      # (job_id: ...) / ----- / To stop or manage this job..." header/footer.
      cron.wrap_response = false;

      # ── Daimon council: webhook face --------------------------------------
      # The webhook-face Discord platform lives in its own plugin
      # (daimon-webhook-plugin). Forma alone runs built-in memory.
      plugins.enabled = [
        "daimon-webhook-plugin"
        # Ponytail (lazy senior dev) — enabled for the top-level profile;
        # Gage's operating bible (08-31). Per-profile configs (profiles/*/
        # config.yaml) are standalone files, NOT managed by this module —
        # they carry their own plugins.enabled. Daimon personas are excluded.
        "ponytail"
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
          profile = "daimon_aisling";
        }
        {
          name = "chrysarch-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1533492889496322108";
          profile = "daimon_chrysarch";
        }
        {
          name = "forma-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1533919537903439872";
          profile = "daimon_forma";
        }
        {
          name = "forma-project-1";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1540017080437317673";
          profile = "daimon_forma";
        }
        {
          name = "forma-project-2";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1540017139975721161";
          profile = "daimon_forma";
        }
        {
          name = "forma-project-3";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1540017200532820038";
          profile = "daimon_forma";
        }
        {
          name = "kyunesnare-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1535998391568306186";
          profile = "daimon_kyunesnare";
        }
        {
          name = "rubedo-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1537265194739433482";
          profile = "daimon_rubedo";
        }
        {
          name = "dante-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1540348781311299644";
          profile = "daimon_dante";
        }
        {
          name = "dragonfall-channel";
          platform = "discord";
          guild_id = "1345013449272459366";
          chat_id = "1538282405985652860";
          profile = "daimon_dante";
        }
        # Project channels (per-project dev workspaces, routed to the `dev` worker).
        # Added 2026-08-21: Gage contains dev projects one-per-channel.
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

      # Global mention-free (Metamageia, 08-25): the bot responds in every
      # channel its role can see without an @mention. The Discord category
      # role now does the boundary work the per-channel list used to, so the
      # free_response allowlist is gone — create a channel, the bot is already
      # there, no config edit, no restart.
      discord.require_mention = false;
      # Reply inline in the channel, never spawn a thread (Metamageia, 08-25;
      # he dislikes threads). This restores the behavior the free_response
      # list used to provide, now globally.
      discord.auto_thread = false;

      # Council-room conduct for #convocatory was dante's voice; it moved to
      # dante's profile with the daimon migration (2026-08-21). The default
      # agent monitors #convocatory as a plain channel until a moderator
      # prompt is reassigned.
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

  # Hermes desktop app (Electron GUI) for this pinned hermes-agent rev
  # (03fa32c…). At this pin it is exposed ONLY as a flake package —
  # inputs.hermes-agent.packages.<system>.desktop — with no services/programs
  # option. It is distinct from the CLI that services.hermes-agent.addToSystemPackages
  # installs, so we add it to the system environment directly to get
  # `hermes-desktop` and its .desktop entry / icon.
  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
  ];
}
