{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.homelab.nixosModules.homelab
  ];

  homelab = {
    sopsFile = ../../secrets/homelab.secrets.yaml;
    clusterSecret = config.sops.secrets.clusterSecret.path;
  };

  sops.secrets = {
    "clusterSecret" = {
      sopsFile = config.homelab.clusterSecret;
      format = "yaml";
    };
  };
}
