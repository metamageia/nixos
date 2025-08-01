{
  pkgs,
  config,
  ...
}: {
  imports = [
    inputs.attic.nixosModules.atticd
  ];

  sops.secrets = {
    "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64" = {
      sopsFile = ../../secrets/secrets.env;
      format = "dotenv";
    };

    services.atticd = {
      enable = true;

      # Replace with absolute path to your environment file
      environmentFile = config.sops.secrets."ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64".path;

      settings = {
        listen = "[::]:8080";
        jwt = {};
        chunking = {
          nar-size-threshold = 64 * 1024; # 64 KiB
          min-size = 16 * 1024; # 16 KiB
          avg-size = 64 * 1024; # 64 KiB
          max-size = 256 * 1024; # 256 KiB
        };
      };
    };
  };
}
