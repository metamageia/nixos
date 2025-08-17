{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./common.nix];
  services.k3s = {
    role = "agent";
    tokenFile = config.sops.secrets.clusterSecret.path;
    #serverAddr = "https://192.168.100.1:6443";
    serverAddr = "https://167.99.123.140:6443";
  };
}
