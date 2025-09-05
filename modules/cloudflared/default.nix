{
  config,
  pkgs,
  userValues,
  hostName,
  ...
}: {

sops.secrets = {
    "cloudflared/${hostName}/token" = {
      sopsFile = userValues.sopsFile;
    };
    "cloudflared/${hostName}/cert.pem" = {
      sopsFile = userValues.sopsFile;
    };
    "saiadha-tunnel.json" = {
      format = "json";
      sopsFile = "${userValues.secretsDir}/saiadha-tunnel.json";
      key = "";
    };
  };

environment.systemPackages = with pkgs; [
    cloudflared
  ];

services.cloudflared = {
    enable = true;
    tunnels = {
      "saiadha-tunnel" = {
        credentialsFile = "${config.sops.secrets."saiadha-tunnel.json".path}";
        default = "http_status:404";
      };
    };
  };

}