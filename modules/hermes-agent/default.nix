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
  };

  sops.templates."hermes.env".content = ''
    DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-discord"}
    DISCORD_ALLOWED_USERS=663086185920331777
  '';

  systemd.services.hermes-agent.serviceConfig.ReadWritePaths = ["/home/metamageia"];

  systemd.services.hermes-agent.serviceConfig.NoNewPrivileges = lib.mkForce false;
  systemd.services.hermes-agent.environment.HOME = lib.mkForce "/home/metamageia";

  systemd.services.hermes-agent.path = [
    config.hardware.nvidia.package.bin
    "/run/current-system/sw"
  ];

  systemd.services.hermes-agent.environment.LD_LIBRARY_PATH = "${config.hardware.nvidia.package}/lib";

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

    extraDependencyGroups = ["messaging" "firecrawl"];
    authFile = config.sops.secrets."hermes-auth".path;

    environmentFiles = [config.sops.templates."hermes.env".path];

    settings = {
      terminal.cwd = "/home/metamageia";
      agent.api_max_retries = 10;

      model = {
        default = "deepseek/deepseek-v4.1-flash";
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
      ];

      gateway.multiplex_profiles = true;

      gateway.profile_routes = [
      ];
      discord.require_mention = false;
      discord.auto_thread = true;
    };
  };
  environment.systemPackages = [
    inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
  ];
}
