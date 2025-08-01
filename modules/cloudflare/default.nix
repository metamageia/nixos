{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  sops.secrets = {
    "cloudflare/token" = {};
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "65f3a635-36d6-47f2-93bd-22903f0cd5dd" = {
        credentialsFile = config.sops.secrets."cloudflare/token".path;
        default = "http_status:404";
      };
    };
  };
}
