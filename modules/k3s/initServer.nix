{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./common.nix];
  services.k3s = {
    role = "server";
    clusterInit = true;
    services.k3s = {
    enable = true;
  };
  };
}
