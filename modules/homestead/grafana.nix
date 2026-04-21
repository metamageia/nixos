{
  config,
  pkgs,
  userValues,
  ...
}: {
  sops.secrets."homestead/grafana_admin_password" = {
    sopsFile = userValues.sopsFile;
    owner = "grafana";
  };
  sops.secrets."homestead/grafana_secret_key" = {
    sopsFile = userValues.sopsFile;
    owner = "grafana";
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "saiadha";
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets."homestead/grafana_admin_password".path}}";
        secret_key = "$__file{${config.sops.secrets."homestead/grafana_secret_key".path}}";
      };
      "auth.anonymous" = {
        enabled = true;
        org_role = "Viewer";
      };
    };
    provision = {
      enable = true;
      datasources.settings.deleteDatasources = [
        {
          name = "Homestead";
          orgId = 1;
        }
      ];
      datasources.settings.datasources = [
        {
          name = "Homestead";
          type = "postgres";
          uid = "homestead-pg";
          url = "/run/postgresql";
          database = "homestead";
          user = "grafana";
          jsonData = {
            database = "homestead";
            sslmode = "disable";
            postgresVersion = 1600;
          };
          isDefault = true;
        }
      ];
      dashboards.settings.providers = [
        {
          name = "Homestead";
          type = "file";
          options.path = "${./dashboards}";
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [3000];
}
