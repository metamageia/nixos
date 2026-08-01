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
  };

  sops.templates."hermes.env".content = ''
    DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-discord"}
  '';

  # Run as the login user so the agent can reach /home/metamageia, which is
  # 0700 and otherwise untraversable by a dedicated service user.
  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = ["/home/metamageia"];

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

    environment = {
      DISCORD_HOME_CHANNEL = "1532688784796291164";
      DISCORD_ALLOWED_USERS = "663086185920331777";

      # Hermes otherwise tightens HERMES_HOME to 0700 (secure_parent_dir),
      # which locks the hermes group out of the shared state dir.
      HERMES_HOME_MODE = "2770";
    };

    settings = {
      # Overrides the workingDirectory-derived default. Set here rather than via
      # workingDirectory, whose tmpfiles rule would chmod 2770 / chgrp the home.
      terminal.cwd = "/home/metamageia";

      model = {
        default = "deepseek/deepseek-v4-flash-0731";
        provider = "nous";
        base_url = "https://inference-api.nousresearch.com/v1";
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
        skin = "hermes";
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
      approvals.destructive_slash_confirm = false;
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
