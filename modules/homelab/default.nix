{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    #inputs.homelab.nixosModules.homelab
    ../k3s
    ../nebula
  ];

  environment.systemPackages = with pkgs; [qbittorrent];
}
