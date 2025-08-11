{
  inputs,
  config,
  pkgs,
  system,
  ...
}: {
  imports = [
    ./k3s
    ./nebula
  ];
  environment.systemPackages = with pkgs; [qbittorrent];
}
