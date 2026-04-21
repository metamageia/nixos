{
  config,
  pkgs,
  userValues,
  ...
}: {
  imports = [
    ./postgresql.nix
    ./grafana.nix
    ./upload-server.nix
  ];
}
