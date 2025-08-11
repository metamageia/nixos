{
  config,
  pkgs,
  ...
}: {
  imports = [./common.nix];

  services.nebula.networks.mesh = {
    isLighthouse = false;
    staticHostMap = {
      "192.168.100.1" = [
        "134.199.241.26:4242"
      ];
    };
    lighthouses = ["192.168.100.1"];
  };
}
