{
  config,
  pkgs,
  lib,
  ...
}: {
  options = {
    services.openWebUI = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Open WebUI (container that connects to local Ollama)";
      };

      image = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/open-webui/open-webui:main";
        description = "Container image to use for Open WebUI";
      };

      listenPort = lib.mkOption {
        type = lib.types.int;
        default = 3000;
        description = "Port for the web UI (default: 3000)";
      };
    };
  };

  config = lib.mkIf config.services.openWebUI.enable {
    virtualisation.podman.enable = true;

    virtualisation.oci-containers = {
      backend = "podman";
      containers.open-webui = {
        image = config.services.openWebUI.image;
        ports = ["${toString config.services.openWebUI.listenPort}:8080"];
        volumes = ["open-webui:/app/backend/data"];
        environment = {
          OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        };
        extraOptions = ["--network=host"];
      };
    };
  };
}
