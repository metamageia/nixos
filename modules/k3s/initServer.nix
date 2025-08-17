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
    extraFlags = [
      "--advertise-address=167.99.123.140"
    ];
  };
}
