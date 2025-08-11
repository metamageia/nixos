{
  config,
  pkgs,
  ...
}: {
  imports = [./common.nix];
  services.nebula.networks.mesh = {
    isLighthouse = true;
  };
}
