{
  config,
  pkgs,
  userValues,
  hostName,
  ...
}: {

  sops.secrets = {
    "saiadha-tunnel" = {
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
        credentialsFile = "${config.sops.secrets."saiadha-tunnel".path}";
        default = "http_status:404";
      };
    };
  };
}
