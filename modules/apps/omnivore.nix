# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."omnivore-api" = {
    image = "ceramicwhite/omnivore:api-latest";
    environment = {
      "JWT_SECRET" = "some_secret";
      "PG_DB" = "omnivore";
      "PG_HOST" = "postgres";
      "PG_PASSWORD" = "app_pass";
      "PG_USER" = "app_user";
      "REDIS_URL" = "redis://redis:6379";
      "SSO_JWT_SECRET" = "some_sso_secret";
    };
    ports = [
      "4000:8080/tcp"
    ];
    dependsOn = [
      "omnivore-migrate"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=api"
      "--network=omnivore_default"
    ];
  };
  systemd.services."podman-omnivore-api" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-omnivore_default.service"
    ];
    requires = [
      "podman-network-omnivore_default.service"
    ];
    partOf = [
      "podman-compose-omnivore-root.target"
    ];
    wantedBy = [
      "podman-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-content-fetch" = {
    image = "ceramicwhite/omnivore:content-fetch-latest";
    environment = {
      "JWT_SECRET" = "some_secret";
      "REDIS_URL" = "redis://redis:6379";
      "REST_BACKEND_ENDPOINT" = "http://api:8080/api";
    };
    ports = [
      "9090:8080/tcp"
    ];
    dependsOn = [
      "omnivore-api"
      "omnivore-redis"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=content-fetch"
      "--network=omnivore_default"
    ];
  };
  systemd.services."podman-omnivore-content-fetch" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-omnivore_default.service"
    ];
    requires = [
      "podman-network-omnivore_default.service"
    ];
    partOf = [
      "podman-compose-omnivore-root.target"
    ];
    wantedBy = [
      "podman-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-migrate" = {
    image = "ceramicwhite/omnivore:migrate-latest";
    environment = {
      "PGPASSWORD" = "postgres";
      "PG_DB" = "omnivore";
      "PG_HOST" = "postgres";
      "PG_PASSWORD" = "app_pass";
      "POSTGRES_USER" = "postgres";
    };
    dependsOn = [
      "omnivore-postgres"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=migrate"
      "--network=omnivore_default"
    ];
  };
  systemd.services."podman-omnivore-migrate" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-omnivore_default.service"
    ];
    requires = [
      "podman-network-omnivore_default.service"
    ];
    partOf = [
      "podman-compose-omnivore-root.target"
    ];
    wantedBy = [
      "podman-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-postgres" = {
    image = "ankane/pgvector:v0.5.1";
    environment = {
      "POSTGRES_DB" = "omnivore";
      "POSTGRES_PASSWORD" = "postgres";
      "POSTGRES_USER" = "postgres";
    };
    ports = [
      "5432:5432/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=exit 0"
      "--health-interval=2s"
      "--health-retries=3"
      "--health-timeout=12s"
      "--network-alias=postgres"
      "--network=omnivore_default"
    ];
  };
  systemd.services."podman-omnivore-postgres" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-omnivore_default.service"
    ];
    requires = [
      "podman-network-omnivore_default.service"
    ];
    partOf = [
      "podman-compose-omnivore-root.target"
    ];
    wantedBy = [
      "podman-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-redis" = {
    image = "redis:7.2.4";
    ports = [
      "6379:6379/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=[\"redis-cli\", \"--raw\", \"incr\", \"ping\"]"
      "--network-alias=redis"
      "--network=omnivore_default"
    ];
  };
  systemd.services."podman-omnivore-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-omnivore_default.service"
    ];
    requires = [
      "podman-network-omnivore_default.service"
    ];
    partOf = [
      "podman-compose-omnivore-root.target"
    ];
    wantedBy = [
      "podman-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-web" = {
    image = "ceramicwhite/omnivore:web-latest";
    environment = {
      "NEXT_PUBLIC_APP_ENV" = "prod";
      "NEXT_PUBLIC_BASE_URL" = "http://localhost:3000";
      "NEXT_PUBLIC_SERVER_BASE_URL" = "http://localhost:4000";
    };
    ports = [
      "3000:8080/tcp"
    ];
    dependsOn = [
      "omnivore-api"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=web"
      "--network=omnivore_default"
    ];
  };
  systemd.services."podman-omnivore-web" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-omnivore_default.service"
    ];
    requires = [
      "podman-network-omnivore_default.service"
    ];
    partOf = [
      "podman-compose-omnivore-root.target"
    ];
    wantedBy = [
      "podman-compose-omnivore-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-omnivore_default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f omnivore_default";
    };
    script = ''
      podman network inspect omnivore_default || podman network create omnivore_default
    '';
    partOf = [ "podman-compose-omnivore-root.target" ];
    wantedBy = [ "podman-compose-omnivore-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-omnivore-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
