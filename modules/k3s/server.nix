{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./common.nix];
  services.k3s = {
    role = "server";
    serverAddr = "https://192.168.100.1:6443";
  };
}
