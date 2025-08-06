{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    #inputs.homelab.nixosModules.homelab
  ];

  environment.systemPackages = with pkgs; [k3s];

  sops.secrets = {
    "clusterSecret" = {
      sopsFile = ../../secrets/homelab.secrets.yaml;
    };
  };

  services.k3s = {
    enable = true;
    role = "server";
    serverAddr = "http://104.131.160.63:6443";
    tokenFile = config.sops.secrets.clusterSecret.path;
  };
}
