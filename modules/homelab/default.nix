{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.homelab.nixosModules.homelab-node
  ];

  homelab-node = {
    homelabSopsFile = "../../secrets/homelab.secrets.yaml";
  };

}
