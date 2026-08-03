{
  config,
  pkgs,
  lib,
  userValues,
  ...
}: {
  imports = [./common.nix];
  services.k3s = {
    clusterInit = true;
    extraFlags = [
      "--node-external-ip=${userValues.publicIP}"
    ];
  };
}
