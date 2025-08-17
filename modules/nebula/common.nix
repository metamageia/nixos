{
  config,
  pkgs,
  hostName,
  sopsFile,
  ...
}: {
  environment.systemPackages = with pkgs; [nebula];

  sops.secrets = {
    "nebula/${hostName}.key" = {
      sopsFile = sopsFile;
      owner = "root";
      group = "nebula-mesh";
      mode = "0640";
    };
    "nebula/${hostName}.crt" = {
      sopsFile = sopsFile;
      owner = "root";
      group = "nebula-mesh";
      mode = "0644";
    };
    "nebula/ca.crt" = {
      sopsFile = sopsFile;
      owner = "root";
      group = "nebula-mesh";
      mode = "0644";
    };
  };

  services.nebula.networks.mesh = {
    enable = false;
    cert = config.sops.secrets."nebula/${hostName}.crt".path;
    key = config.sops.secrets."nebula/${hostName}.key".path;
    ca = config.sops.secrets."nebula/ca.crt".path; #08-09-2026
    firewall = {
      inbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
      outbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
    };
  };
}
