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
    role = "agent";
    serverAddr = "https://192.168.100.1:6443";
  };
}
