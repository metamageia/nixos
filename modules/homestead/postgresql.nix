{
  config,
  pkgs,
  ...
}: {
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = ["homestead"];
    ensureUsers = [
      {
        name = "homestead";
        ensureDBOwnership = true;
      }
      {
        name = "grafana";
      }
      {
        name = "metamageia";
      }
    ];
    authentication = ''
      local homestead grafana peer
      local homestead homestead peer
      local homestead metamageia peer
    '';
  };

  # Schema migration service - runs idempotent SQL on every boot
  systemd.services.homestead-schema = {
    description = "Homestead DB schema migration";
    after = ["postgresql.service" "postgresql-setup.service"];
    requires = ["postgresql.service" "postgresql-setup.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = "${pkgs.postgresql_16}/bin/psql -d homestead -f ${./schema.sql}";
    };
  };

  # System user for the homestead services
  users.users.homestead = {
    isSystemUser = true;
    group = "homestead";
    home = "/var/lib/homestead";
    createHome = true;
  };
  users.groups.homestead = {};

  # Upload directory
  systemd.tmpfiles.rules = [
    "d /var/lib/homestead/uploads 0775 homestead homestead -"
  ];
}
