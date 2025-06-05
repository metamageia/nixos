# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."omnivore-api" = {
    image = "compose2nix/omnivore-api";
    environment = {
      "API_ENV" = "local";
      "CLIENT_URL" = "http://localhost:3000";
      "CONTENT_FETCH_URL" = "http://content-fetch:8080/?token=some_token";
      "GATEWAY_URL" = "http://localhost:8080/api";
      "IMAGE_PROXY_SECRET" = "some-secret";
      "JAEGER_HOST" = "jaeger";
      "JWT_SECRET" = "some_secret";
      "PG_DB" = "omnivore";
      "PG_HOST" = "postgres";
      "PG_PASSWORD" = "app_pass";
      "PG_POOL_MAX" = "20";
      "PG_PORT" = "5432";
      "PG_USER" = "app_user";
      "REDIS_URL" = "'redis://redis:6379'";
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
      "--health-cmd=nc -z 0.0.0.0 8080 || exit 1"
      "--health-interval=15s"
      "--health-timeout=1m30s"
      "--network-alias=api"
      "--network=omnivore_default"
    ];
  };
  systemd.services."docker-omnivore-api" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-network-omnivore_default.service"
    ];
    requires = [
      "docker-network-omnivore_default.service"
    ];
    partOf = [
      "docker-compose-omnivore-root.target"
    ];
    wantedBy = [
      "docker-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-content-fetch" = {
    image = "compose2nix/omnivore-content-fetch";
    environment = {
      "JWT_SECRET" = "some_secret";
      "REDIS_URL" = "redis://redis:6379";
      "REST_BACKEND_ENDPOINT" = "http://api:8080/api";
      "VERIFICATION_TOKEN" = "some_token";
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
  systemd.services."docker-omnivore-content-fetch" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-network-omnivore_default.service"
    ];
    requires = [
      "docker-network-omnivore_default.service"
    ];
    partOf = [
      "docker-compose-omnivore-root.target"
    ];
    wantedBy = [
      "docker-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-migrate" = {
    image = "compose2nix/omnivore-migrate";
    environment = {
      "PGPASSWORD" = "postgres";
      "PG_DB" = "omnivore";
      "PG_HOST" = "postgres";
      "PG_PASSWORD" = "app_pass";
      "POSTGRES_USER" = "postgres";
    };
    cmd = [ "/bin/sh" "./packages/db/setup.sh" ];
    dependsOn = [
      "omnivore-postgres"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=migrate"
      "--network=omnivore_default"
    ];
  };
  systemd.services."docker-omnivore-migrate" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-network-omnivore_default.service"
    ];
    requires = [
      "docker-network-omnivore_default.service"
    ];
    partOf = [
      "docker-compose-omnivore-root.target"
    ];
    wantedBy = [
      "docker-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-postgres" = {
    image = "ankane/pgvector:v0.5.1";
    environment = {
      "PG_POOL_MAX" = "20";
      "POSTGRES_DB" = "omnivore";
      "POSTGRES_HOST_AUTH_METHOD" = "scram-sha-256
  host replication all 0.0.0.0/0 md5";
      "POSTGRES_INITDB_ARGS" = "--auth-host=scram-sha-256";
      "POSTGRES_PASSWORD" = "postgres";
      "POSTGRES_USER" = "postgres";
    };
    ports = [
      "5432:5432/tcp"
    ];
    cmd = [ "postgres" "-c" "wal_level=replica" "-c" "hot_standby=on" "-c" "max_wal_senders=10" "-c" "max_replication_slots=10" "-c" "hot_standby_feedback=on" ];
    user = "postgres";
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
  systemd.services."docker-omnivore-postgres" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-network-omnivore_default.service"
    ];
    requires = [
      "docker-network-omnivore_default.service"
    ];
    partOf = [
      "docker-compose-omnivore-root.target"
    ];
    wantedBy = [
      "docker-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-postgres-replica" = {
    image = "ankane/pgvector:v0.5.1";
    environment = {
      "PGPASSWORD" = "replicator_password";
      "PGUSER" = "replicator";
    };
    ports = [
      "5433:5432/tcp"
    ];
    cmd = [ "bash" "-c" "
  until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=replication_slot --host=postgres --port=5432
  do
  echo 'Waiting for primary to connect...'
  sleep 1s
  done
  echo 'Backup done, starting replica...'
  chmod 0700 /var/lib/postgresql/data
  postgres
  " ];
    dependsOn = [
      "omnivore-postgres"
    ];
    user = "postgres";
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=exit 0"
      "--health-interval=2s"
      "--health-retries=3"
      "--health-timeout=12s"
      "--network-alias=postgres-replica"
      "--network=omnivore_default"
    ];
  };
  systemd.services."docker-omnivore-postgres-replica" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-network-omnivore_default.service"
    ];
    requires = [
      "docker-network-omnivore_default.service"
    ];
    partOf = [
      "docker-compose-omnivore-root.target"
    ];
    wantedBy = [
      "docker-compose-omnivore-root.target"
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
  systemd.services."docker-omnivore-redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-network-omnivore_default.service"
    ];
    requires = [
      "docker-network-omnivore_default.service"
    ];
    partOf = [
      "docker-compose-omnivore-root.target"
    ];
    wantedBy = [
      "docker-compose-omnivore-root.target"
    ];
  };
  virtualisation.oci-containers.containers."omnivore-web" = {
    image = "compose2nix/omnivore-web";
    environment = {
      "NEXT_PUBLIC_APP_ENV" = "prod";
      "NEXT_PUBLIC_BASE_URL" = "http://localhost:3000";
      "NEXT_PUBLIC_HIGHLIGHTS_BASE_URL" = "http://localhost:3000";
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
  systemd.services."docker-omnivore-web" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "docker-network-omnivore_default.service"
    ];
    requires = [
      "docker-network-omnivore_default.service"
    ];
    partOf = [
      "docker-compose-omnivore-root.target"
    ];
    wantedBy = [
      "docker-compose-omnivore-root.target"
    ];
  };

  # Networks
  systemd.services."docker-network-omnivore_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f omnivore_default";
    };
    script = ''
      docker network inspect omnivore_default || docker network create omnivore_default
    '';
    partOf = [ "docker-compose-omnivore-root.target" ];
    wantedBy = [ "docker-compose-omnivore-root.target" ];
  };

  # Builds
  systemd.services."docker-build-omnivore-api" = {
    path = [ pkgs.docker pkgs.git ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutSec = 300;
    };
    script = ''
      cd /home/metamageia/Documents/.dotfiles
      docker build -t compose2nix/omnivore-api -f ./packages/api/Dockerfile .
    '';
  };
  systemd.services."docker-build-omnivore-content-fetch" = {
    path = [ pkgs.docker pkgs.git ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutSec = 300;
    };
    script = ''
      cd /home/metamageia/Documents/.dotfiles
      docker build -t compose2nix/omnivore-content-fetch -f ./packages/content-fetch/Dockerfile .
    '';
  };
  systemd.services."docker-build-omnivore-migrate" = {
    path = [ pkgs.docker pkgs.git ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutSec = 300;
    };
    script = ''
      cd /home/metamageia/Documents/.dotfiles
      docker build -t compose2nix/omnivore-migrate -f ./packages/db/Dockerfile .
    '';
  };
  systemd.services."docker-build-omnivore-web" = {
    path = [ pkgs.docker pkgs.git ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutSec = 300;
    };
    script = ''
      cd /home/metamageia/Documents/.dotfiles
      docker build -t compose2nix/omnivore-web --build-arg BASE_URL=http://localhost:3000 --build-arg SERVER_BASE_URL=http://localhost:4000 --build-arg HIGHLIGHTS_BASE_URL=http://localhost:3000 --build-arg APP_ENV=prod -f ./packages/web/Dockerfile .
    '';
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-omnivore-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
