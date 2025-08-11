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
    enable = true;
    isLighthouse = false;
    cert = config.sops.secrets."nebula/${hostName}.crt".path;
    key = config.sops.secrets."nebula/${hostName}.key".path;
    ca = config.sops.secrets."nebula/ca.crt".path; #08-09-2026
    staticHostMap = {
      "192.168.100.1" = [
        "134.199.241.26:4242"
      ];
    };
    lighthouses = ["192.168.100.1"];
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
