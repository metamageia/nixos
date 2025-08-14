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
        "auriga.gagelara.com:4242"
      ];
    };
    lighthouses = ["192.168.100.1"];
  };
}
