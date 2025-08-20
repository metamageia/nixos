{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./common.nix];
  services.k3s = {
    clusterInit = true;
    extraFlags = [
      "--node-external-ip=167.99.123.140"
    ];
  };
}
