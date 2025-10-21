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
        "167.99.123.140:4242"
      ];
    };
    lighthouses = ["192.168.100.1"];
  };
}
