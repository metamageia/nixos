{
  config,
  pkgs,
  userValues,
  hostName,
  ...
}: {

# From the wiki: To get credentialsFile (e.g. tunnel-ID.json) do: 
# cloudflared tunnel login <the-token-you-see-in-dashboard>
# cloudflared tunnel create ConvenientTunnelName

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