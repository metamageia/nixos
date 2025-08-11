{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./default.nix
  ];
  services.k3s = {
    role = "server";
    clusterInit = true;
  };
}
