{
  config,
  pkgs,
  userValues,
  ...
}: {
  imports = [./common.nix];

  services.nebula.networks.mesh = {
    isLighthouse = false;
    staticHostMap = {
      "192.168.100.1" = [
        "${userValues.publicHost}:4242"
      ];
    };
    lighthouses = ["192.168.100.1"];
  };
}
