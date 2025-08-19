{
  pkgs,
  inputs,
  system,
  ...
}: {
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [
    compose2nix
    docker-compose
    inputs.compose2nix.packages.x86_64-linux.default
  ];
}
