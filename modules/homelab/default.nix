{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.homelab.nixosModules.homelab
  ];

  homelab = {
    sopsFile = ../../secrets/personal.secrets.yaml;
  };

}
