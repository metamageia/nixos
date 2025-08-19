{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./server.nix];
  services.k3s = {
    clusterInit = true;
  };
}
