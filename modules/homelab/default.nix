{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    #inputs.homelab.nixosModules.homelab
  ];

  environment.systemPackages = with pkgs; [k3s];
}
