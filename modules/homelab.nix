{
  inputs,
  config,
  pkgs,
  system,
  ...
}: {
  imports = [
    ./k3s
  ];
  environment.systemPackages = with pkgs; [];
}
