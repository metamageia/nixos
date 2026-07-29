{
  inputs,
  pkgs,
  config,
  lib,
  userValues,
  ...
}: {
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
    "sigilla-discord" = {
      sopsFile = "${userValues.secretsDir}/personal.secrets.yaml";
    };
  };

  sops.templates."hermes.env".content = ''
    DISCORD_BOT_TOKEN=${config.sops.placeholder."sigilla-discord"}
  '';

  # Run as the login user so the agent can reach /home/metamageia, which is
  # 0700 and otherwise untraversable by a dedicated service user.
  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = ["/home/metamageia"];

  # Upstream pins HOME to stateDir, which makes the agent believe its home is
  # /var/lib/hermes. HERMES_HOME is set separately, so state still resolves.
  systemd.services.hermes-agent.environment.HOME = lib.mkForce "/home/metamageia";

  services.hermes-agent = {
    enable = true;
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.minimal;
    addToSystemPackages = true;

    user = "metamageia";
    createUser = false;

    # `minimal` omits discord.py, and hermes' lazy-installer cannot write to
    # the read-only /nix/store, so the dep must be baked in at build time.
    extraDependencyGroups = ["messaging"];

    # Seeded once; hermes refreshes the OAuth token in place afterward.
    authFile = config.sops.secrets."hermes-auth".path;

    environmentFiles = [config.sops.templates."hermes.env".path];

    environment = {
      DISCORD_HOME_CHANNEL = "1531817978138464399";
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
        default = "minimax/minimax-m3";
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
        skin = "sigilla";
      };
      tts = {
        provider = "openai";
        use_gateway = true;
      };
      stt = {
        provider = "openai";
        use_gateway = true;
      };
      image_gen.use_gateway = true;
      approvals.destructive_slash_confirm = false;
    };
  };
}
